// Copyright (C) 2020-2022 SubQuery Pte Ltd authors & contributors
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.15;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

import './interfaces/ISettings.sol';
import './interfaces/IEraManager.sol';
import './interfaces/IPermissionedExchange.sol';
import './interfaces/IPermissionedExchange.sol';
import './interfaces/IRewardsDistributer.sol';
import './interfaces/IRewardsPool.sol';
import './interfaces/IRewardsStaking.sol';
import './interfaces/IServiceAgreementRegistry.sol';
import './interfaces/IIndexerRegistry.sol';
import './interfaces/IStaking.sol';
import './interfaces/IStakingManager.sol';
import './Constants.sol';
import './utils/MathUtil.sol';

/**
 * @title Rewards Distributer Contract
 * @notice ### Overview
 * The Rewards distributer contract tracks and distriubtes the rewards Era by Era.
 * In each distribution, Indexers can take the commission part of rewards, the remaining
 * rewards are distributed according to the staking amount of indexers and delegators.
 *
 * ### Terminology
 * Era -- Era is the period of reward distribution. In our design, we must distribute the rewards of the previous Era
 * before we can move to the next Era.
 * Commission Rate -- Commission Rates are set by Indexers, it is the proportion to be taken by the indexer in each
 * reward distribution.
 * Rewards -- Rewards are paid by comsumer for the service agreements with indexer. All the rewards are
 * temporary hold by RewardsDistributer contract and distribute to Indexers and Delegator Era by Era.
 *
 * ### Detail
 * In the design of rewards distribution, we have added a trade-off mechanism for Indexer and
 * Delegator to achieve a win-win situation.
 * The more SQT token staked on an indexer, the higher limitation of ongoing agreements the indexer can have. In order to earn more rewards with extra agreements,
 * Indexers can stake more to themself, or attract delegators delegate to them, and delegators can share the
 * rewards base on their delegation.
 * This distribution strategy ensures the quality of service and makes both indexers and delegators profitable.
 *
 * We apply delegation amount changes at next era and commission rate changes are applied at two Eras later. We design this
 * to allow time for the delegators to consider their delegation when an Indxer changes the commission rate. But the first stake
 * change and commission rate change of an indexer that made on registration are applied immediately, In this way, the rewards
 * on the era that indexer registered can also be distributed correctly.
 *
 * After the service agreements generated from PlanManager and PurchaseOfferMarket, the rewards paied by consumer are temporary hold by
 * RewardsDistributer contract. RewardsDistributer first linearly split these rewards into Eras according to the era period and the period
 * of the agreement. The distribution information are stored in eraRewardAddTable and eraRewardRemoveTable.
 * In the specific distribution process, we calculate the rewards need to be distributed according to eraRewardAddTable and eraRewardRemoveTable,
 * and distribute to Indexers and Delegators according to their stake amount at that time.
 * Indexer's commission part of the rewards will transfer to indexer immediately after each distribution. And Indexer and delegator can claim
 * accumulated rewards by call claim() any time.
 *
 */
contract RewardsDistributer is IRewardsDistributer, Initializable, OwnableUpgradeable, Constants {
    using SafeERC20 for IERC20;
    using MathUtil for uint256;

    /**
     * @notice Reward information. One per Indexer.
     */
    struct RewardInfo {
        uint256 accSQTPerStake;
        mapping(address => uint256) rewardDebt;
        uint256 lastClaimEra;
        uint256 eraReward;
        mapping(uint256 => uint256) eraRewardAddTable;
        mapping(uint256 => uint256) eraRewardRemoveTable;
    }

    /// @dev ### STATES
    /// @notice ISettings contract which stores SubQuery network contracts address
    ISettings private settings;
    /// @notice Reward information: indexer => RewardInfo
    mapping(address => RewardInfo) private info;

    /// @dev ### EVENTS
    /// @notice Emitted when rewards are distributed for the earliest pending distributed Era.
    event DistributeRewards(address indexed indexer, uint256 indexed eraIdx, uint256 rewards, uint256 commission);
    /// @notice Emitted when user claimed rewards.
    event ClaimRewards(address indexed indexer, address indexed delegator, uint256 rewards);
    /// @notice Emitted when the rewards change, such as when rewards coming from new agreement.
    event RewardsChanged(address indexed indexer, uint256 indexed eraIdx, uint256 additions, uint256 removals);

    modifier onlyRewardsStaking() {
        require(msg.sender == settings.getRewardsStaking(), 'G014');
        _;
    }

    /**
     * @dev FUNCTIONS
     * @notice Initialize this contract.
     */
    function initialize(ISettings _settings) external initializer {
        __Ownable_init();

        //Settings
        settings = _settings;
    }

    function setSettings(ISettings _settings) external onlyOwner {
        settings = _settings;
    }

    /**
     * @notice Initialize the indexer first last claim era.
     * Only RewardsStaking can call.
     * @param indexer address
     * @param era uint256
     */
    function setLastClaimEra(address indexer, uint256 era) external onlyRewardsStaking {
        info[indexer].lastClaimEra = era;
    }

    /**
     * @notice Update delegator debt in rewards.
     * Only RewardsStaking can call.
     * @param indexer address
     * @param delegator address
     * @param amount uint256
     */
    function setRewardDebt(address indexer, address delegator, uint256 amount) external onlyRewardsStaking {
        info[indexer].rewardDebt[delegator] = amount;
    }

    /**
     * @notice Reset era reward.
     * Only RewardsStaking can call.
     * @param indexer address
     * @param era uint256
     */
    function resetEraReward(address indexer, uint256 era) external onlyRewardsStaking {
        if (info[indexer].eraRewardRemoveTable[era] == 0) {
            info[indexer].eraReward = 0;
        }
    }

    /**
     * @notice Split rewards from agreemrnt into Eras:
     * Rewards split into one era;
     * Rewards split into two eras;
     * Rewards split into more then two eras handled by splitEraSpanMore;
     * Use eraRewardAddTable and eraRewardRemoveTable to store and track reward split info at RewardInfo.
     * Only be called by ServiceAgreementRegistry contract when new agreement accepted.
     * @param agreementId agreement Id
     */
    function increaseAgreementRewards(uint256 agreementId) external {
        require(settings.getServiceAgreementRegistry() == msg.sender, 'G015');
        ClosedServiceAgreementInfo memory agreement = IServiceAgreementRegistry(settings.getServiceAgreementRegistry()).getClosedServiceAgreement(agreementId);
        require(agreement.consumer != address(0), 'SA001');
        IEraManager eraManager = IEraManager(settings.getEraManager());

        address indexer = agreement.indexer;
        uint256 agreementPeriod = agreement.period;
        uint256 agreementValue = agreement.lockedAmount;
        uint256 agreementStartDate = agreement.startDate;
        uint256 agreementStartEra = eraManager.timestampToEraNumber(agreementStartDate);
        uint256 eraPeriod = eraManager.eraPeriod();

        IERC20(settings.getSQToken()).safeTransferFrom(msg.sender, address(this), agreementValue);

        uint256 estAgreementEnd = agreementStartDate + agreementPeriod;
        uint256 firstEraPortion = MathUtil.min(eraManager.eraStartTime() + (agreementStartEra - eraManager.eraNumber() + 1) * eraPeriod, estAgreementEnd) - agreementStartDate;

        RewardInfo storage rewardInfo = info[indexer];

        if (firstEraPortion == agreementPeriod) {
            // span in one era
            rewardInfo.eraRewardAddTable[agreementStartEra] += agreementValue;
            rewardInfo.eraRewardRemoveTable[agreementStartEra + 1] += agreementValue;
        } else if (agreementPeriod <= eraPeriod + firstEraPortion) {
            // span in two era
            uint256 firstEraReward = MathUtil.mulDiv(firstEraPortion, agreementValue, agreementPeriod);
            uint256 lastEraReward = MathUtil.sub(agreementValue, firstEraReward);
            rewardInfo.eraRewardAddTable[agreementStartEra] += firstEraReward;

            uint256 postEndEra = agreementStartEra + 2;
            rewardInfo.eraRewardAddTable[agreementStartEra + 1] += firstEraReward < lastEraReward ? lastEraReward - firstEraReward : firstEraReward - lastEraReward;
            rewardInfo.eraRewardRemoveTable[postEndEra] += lastEraReward;

            _emitRewardsChangedEvent(indexer, postEndEra, rewardInfo);
        } else {
            // span in > two eras
            uint256 firstEraReward = MathUtil.mulDiv(firstEraPortion, agreementValue, agreementPeriod);
            rewardInfo.eraRewardAddTable[agreementStartEra] += firstEraReward;
            uint256 restEras = MathUtil.divUp(agreementPeriod - firstEraPortion, eraPeriod);
            uint256 rewardForMidEra = MathUtil.mulDiv(eraPeriod, agreementValue, agreementPeriod);
            rewardInfo.eraRewardAddTable[agreementStartEra + 1] += rewardForMidEra - firstEraReward;
            uint256 rewardForLastEra = MathUtil.sub(MathUtil.sub(agreementValue, firstEraReward), rewardForMidEra * (restEras - 1));
            if (rewardForLastEra <= rewardForMidEra) {
                uint256 rewardMinus = MathUtil.sub(rewardForMidEra, rewardForLastEra);
                rewardInfo.eraRewardRemoveTable[restEras + agreementStartEra] += rewardMinus;
                rewardInfo.eraRewardRemoveTable[restEras + agreementStartEra + 1] += rewardForLastEra;
            } else {
                // this could happen due to rounding that rewardForLastEra is one larger than rewardForMidEra
                uint256 rewardAdd = MathUtil.sub(rewardForLastEra, rewardForMidEra);
                rewardInfo.eraRewardAddTable[restEras + agreementStartEra] += rewardAdd;
                rewardInfo.eraRewardRemoveTable[restEras + agreementStartEra + 1] += rewardForLastEra;
            }

            uint256 lastEra = MathUtil.divUp(agreementPeriod - firstEraPortion, eraPeriod) + agreementStartEra;
            // Last era
            _emitRewardsChangedEvent(indexer, lastEra, rewardInfo);

            // Post last era
            _emitRewardsChangedEvent(indexer, lastEra + 1, rewardInfo);
        }

        // Current era will always change
        _emitRewardsChangedEvent(indexer, agreementStartEra, rewardInfo);

        // Next era will always change
        _emitRewardsChangedEvent(indexer, agreementStartEra + 1, rewardInfo);
    }

    /**
     * @notice Send rewards directly to the specified era.
     * Maybe RewardsPool call or others contracts.
     * @param indexer address
     * @param sender address
     * @param amount uint256
     * @param era uint256
     */
    function addInstantRewards(address indexer, address sender, uint256 amount, uint256 era) external {
        require(era <= _getCurrentEra(), 'RD001');
        require(era >= info[indexer].lastClaimEra, 'RD002');
        IERC20(settings.getSQToken()).safeTransferFrom(sender, address(this), amount);

        RewardInfo storage rewardInfo = info[indexer];
        rewardInfo.eraRewardAddTable[era] += amount;
        rewardInfo.eraRewardRemoveTable[era + 1] += amount;

        // Current era will always change
        _emitRewardsChangedEvent(indexer, era, rewardInfo);

        // Next era will always change
        _emitRewardsChangedEvent(indexer, era + 1, rewardInfo);
    }

    /**
     * @notice check if the current Era is claimed.
     */
    function collectAndDistributeRewards(address indexer) public {
        // check current era is after lastClaimEra
        uint256 currentEra = _getCurrentEra();
        require(info[indexer].lastClaimEra < currentEra - 1, 'RD003');
        collectAndDistributeEraRewards(currentEra, indexer);
    }

    /**
     * @notice Calculate and distribute the rewards for the next Era of the lastClaimEra.
     * Calculate by eraRewardAddTable and eraRewardRemoveTable.
     * Distribute by distributeRewards method.
     */
    function collectAndDistributeEraRewards(uint256 currentEra, address indexer) public returns (uint256) {
        RewardInfo storage rewardInfo = info[indexer];
        require(rewardInfo.lastClaimEra > 0, 'RD004');
        // skip when it has been claimed for currentEra - 1, no throws
        if (rewardInfo.lastClaimEra >= currentEra - 1) {
            return rewardInfo.lastClaimEra;
        }

        IRewardsStaking rewardsStaking = IRewardsStaking(settings.getRewardsStaking());
        rewardsStaking.checkAndReflectSettlement(indexer, rewardInfo.lastClaimEra);
        require(rewardInfo.lastClaimEra <= rewardsStaking.getLastSettledEra(indexer), 'RD005');

        rewardInfo.lastClaimEra++;

        // claim rewards pool.
        IRewardsPool rewardsPool = IRewardsPool(settings.getRewardsPool());
        rewardsPool.batchCollectEra(rewardInfo.lastClaimEra, indexer);

        rewardInfo.eraReward += rewardInfo.eraRewardAddTable[rewardInfo.lastClaimEra];
        rewardInfo.eraReward -= rewardInfo.eraRewardRemoveTable[rewardInfo.lastClaimEra];
        delete rewardInfo.eraRewardAddTable[rewardInfo.lastClaimEra];
        delete rewardInfo.eraRewardRemoveTable[rewardInfo.lastClaimEra];
        if (rewardInfo.eraReward != 0) {
            uint256 totalStake = rewardsStaking.getTotalStakingAmount(indexer);
            require(totalStake > 0, 'RD006');

            uint256 commissionRate = IIndexerRegistry(settings.getIndexerRegistry()).getCommissionRate(indexer);
            uint256 commission = MathUtil.mulDiv(commissionRate, rewardInfo.eraReward, PER_MILL);

            info[indexer].accSQTPerStake += MathUtil.mulDiv(rewardInfo.eraReward - commission, PER_TRILL, totalStake);

            // add commission to unbonding request
            IERC20(settings.getSQToken()).safeTransfer(settings.getStaking(), commission);
            IStaking(settings.getStaking()).unbondCommission(indexer, commission);

            emit DistributeRewards(indexer, rewardInfo.lastClaimEra, rewardInfo.eraReward, commission);

            IPermissionedExchange exchange = IPermissionedExchange(settings.getPermissionedExchange());
            exchange.addQuota(settings.getSQToken(), indexer, commission);
        }
        return rewardInfo.lastClaimEra;
    }

    /**
     * @notice Claim rewards of msg.sender for specific indexer.
     */
    function claim(address indexer) public {
        require(claimFrom(indexer, msg.sender) > 0, 'RD007');
    }

    /**
     * @notice Claculate the Rewards for user and tranfrer token to user.
     */
    function claimFrom(address indexer, address user) public returns (uint256) {
        require(!(IEraManager(settings.getEraManager()).maintenance()), 'G019');
        uint256 rewards = userRewards(indexer, user);
        if (rewards == 0) return 0;
        info[indexer].rewardDebt[user] += rewards;

        IERC20(settings.getSQToken()).safeTransfer(user, rewards);

        IPermissionedExchange exchange = IPermissionedExchange(settings.getPermissionedExchange());
        exchange.addQuota(settings.getSQToken(), user, rewards);

        emit ClaimRewards(indexer, user, rewards);
        return rewards;
    }

    /**
     * @notice extract for reuse emit RewardsChanged event
     */
    function _emitRewardsChangedEvent(address indexer, uint256 eraNumber, RewardInfo storage rewardInfo) private {
        emit RewardsChanged(indexer, eraNumber, rewardInfo.eraRewardAddTable[eraNumber], rewardInfo.eraRewardRemoveTable[eraNumber]);
    }

    /**
     * @notice Get current Era number from EraManager.
     */
    function _getCurrentEra() private returns (uint256) {
        IEraManager eraManager = IEraManager(settings.getEraManager());
        return eraManager.safeUpdateAndGetEra();
    }

    function userRewards(address indexer, address user) public view returns (uint256) {
        IRewardsStaking rewardsStaking = IRewardsStaking(settings.getRewardsStaking());
        uint256 delegationAmount = rewardsStaking.getDelegationAmount(user, indexer);

        return MathUtil.mulDiv(delegationAmount, info[indexer].accSQTPerStake, PER_TRILL) - info[indexer].rewardDebt[user];
    }

    function getRewardInfo(address indexer) public view returns (IndexerRewardInfo memory) {
        RewardInfo storage reward = info[indexer];
        return IndexerRewardInfo(reward.accSQTPerStake, reward.lastClaimEra, reward.eraReward);
    }

    function getRewardAddTable(address indexer, uint256 era) public view returns (uint256) {
        return info[indexer].eraRewardAddTable[era];
    }

    function getRewardRemoveTable(address indexer, uint256 era) public view returns (uint256) {
        return info[indexer].eraRewardRemoveTable[era];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// Copyright (C) 2020-2022 SubQuery Pte Ltd authors & contributors
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.15;

interface ISettings {
    function setProjectAddresses(
        address _indexerRegistry,
        address _queryRegistry,
        address _eraManager,
        address _planManager,
        address _serviceAgreementRegistry,
        address _disputeManager,
        address _stateChannel
    ) external;

    function setTokenAddresses(
        address _sqToken,
        address _staking,
        address _stakingManager,
        address _rewardsDistributer,
        address _rewardsPool,
        address _rewardsStaking,
        address _rewardsHelper,
        address _inflationController,
        address _vesting,
        address _permissionedExchange
    ) external;

    function setSQToken(address _sqToken) external;

    function getSQToken() external view returns (address);

    function setStaking(address _staking) external;

    function getStaking() external view returns (address);

    function setStakingManager(address _stakingManager) external;

    function getStakingManager() external view returns (address);

    function setIndexerRegistry(address _indexerRegistry) external;

    function getIndexerRegistry() external view returns (address);

    function setQueryRegistry(address _queryRegistry) external;

    function getQueryRegistry() external view returns (address);

    function setEraManager(address _eraManager) external;

    function getEraManager() external view returns (address);

    function setPlanManager(address _planManager) external;

    function getPlanManager() external view returns (address);

    function setServiceAgreementRegistry(address _serviceAgreementRegistry) external;

    function getServiceAgreementRegistry() external view returns (address);

    function setRewardsDistributer(address _rewardsDistributer) external;

    function getRewardsDistributer() external view returns (address);

    function setRewardsPool(address _rewardsPool) external;

    function getRewardsPool() external view returns (address);

    function setRewardsStaking(address _rewardsStaking) external;

    function getRewardsStaking() external view returns (address);

    function setRewardsHelper(address _rewardsHelper) external;

    function getRewardsHelper() external view returns (address);

    function setInflationController(address _inflationController) external;

    function getInflationController() external view returns (address);

    function setVesting(address _vesting) external;

    function getVesting() external view returns (address);

    function setPermissionedExchange(address _permissionedExchange) external;

    function getPermissionedExchange() external view returns (address);

    function setDisputeManager(address _disputeManager) external;

    function getDisputeManager() external view returns (address);

    function setStateChannel(address _stateChannel) external;

    function getStateChannel() external view returns (address);
}

// Copyright (C) 2020-2022 SubQuery Pte Ltd authors & contributors
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.15;

interface IEraManager {
    function eraStartTime() external view returns (uint256);

    function eraPeriod() external view returns (uint256);

    function eraNumber() external view returns (uint256);

    function safeUpdateAndGetEra() external returns (uint256);

    function timestampToEraNumber(uint256 timestamp) external view returns (uint256);

    function maintenance() external returns (bool);
}

// Copyright (C) 2020-2022 SubQuery Pte Ltd authors & contributors
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.15;

interface IPermissionedExchange {
    function addQuota(address _token, address _account, uint256 _amount) external;
}

// Copyright (C) 2020-2022 SubQuery Pte Ltd authors & contributors
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.15;

import './IServiceAgreementRegistry.sol';

// Reward info for query.
struct IndexerRewardInfo {
    uint256 accSQTPerStake;
    uint256 lastClaimEra;
    uint256 eraReward;
}

interface IRewardsDistributer {
    function setLastClaimEra(address indexer, uint256 era) external;

    function setRewardDebt(address indexer, address delegator, uint256 amount) external;

    function resetEraReward(address indexer, uint256 era) external;

    function collectAndDistributeRewards(address indexer) external;

    function collectAndDistributeEraRewards(uint256 era, address indexer) external returns (uint256);

    function increaseAgreementRewards(uint256 agreementId) external;

    function addInstantRewards(address indexer, address sender, uint256 amount, uint256 era) external;

    function claim(address indexer) external;

    function claimFrom(address indexer, address user) external returns (uint256);

    function userRewards(address indexer, address user) external view returns (uint256);

    function getRewardInfo(address indexer) external view returns (IndexerRewardInfo memory);
}

// Copyright (C) 2020-2022 SubQuery Pte Ltd authors & contributors
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.15;

interface IRewardsPool {
    function getReward(bytes32 deploymentId, uint256 era, address indexer) external returns (uint256, uint256);

    function labor(bytes32 deploymentId, address indexer, uint256 amount) external;

    function collect(bytes32 deploymentId, address indexer) external;

    function collectEra(uint256 era, bytes32 deploymentId, address indexer) external;

    function batchCollectEra(uint256 era, address indexer) external;

    function isClaimed(uint256 era, address indexer) external returns (bool);

    function getUnclaimDeployments(uint256 era, address indexer) external view returns (bytes32[] memory);
}

// Copyright (C) 2020-2022 SubQuery Pte Ltd authors & contributors
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.15;

interface IRewardsStaking {
    function onStakeChange(address indexer, address user) external;

    function onICRChange(address indexer, uint256 startEra) external;

    function applyStakeChange(address indexer, address staker) external;

    function applyICRChange(address indexer) external;

    function checkAndReflectSettlement(address indexer, uint256 lastClaimEra) external returns (bool);

    function getTotalStakingAmount(address _indexer) external view returns (uint256);

    function getLastSettledEra(address indexer) external view returns (uint256);

    function getDelegationAmount(address source, address indexer) external view returns (uint256);
}

// Copyright (C) 2020-2022 SubQuery Pte Ltd authors & contributors
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.15;

// -- Data --

/**
 * @dev closed service agreement information
 */
struct ClosedServiceAgreementInfo {
    address consumer;
    address indexer;
    bytes32 deploymentId;
    uint256 lockedAmount;
    uint256 startDate;
    uint256 period;
    uint256 planId;
    uint256 planTemplateId;
}

interface IServiceAgreementRegistry {
    function establishServiceAgreement(uint256 agreementId) external;

    function hasOngoingClosedServiceAgreement(address indexer, bytes32 deploymentId) external view returns (bool);

    function addUser(address consumer, address user) external;

    function removeUser(address consumer, address user) external;

    function getClosedServiceAgreement(uint256 agreementId) external view returns (ClosedServiceAgreementInfo memory);

    function nextServiceAgreementId() external view returns (uint256);

    function createClosedServiceAgreement(ClosedServiceAgreementInfo memory agreement) external returns (uint256);
}

// Copyright (C) 2020-2022 SubQuery Pte Ltd authors & contributors
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.15;

interface IIndexerRegistry {
    function isIndexer(address _address) external view returns (bool);

    function getController(address indexer) external view returns (address);

    function minimumStakingAmount() external view returns (uint256);

    function getCommissionRate(address indexer) external view returns (uint256);

    function setInitialCommissionRate(address indexer, uint256 rate) external;

    function setCommissionRate(uint256 rate) external;
}

// Copyright (C) 2020-2022 SubQuery Pte Ltd authors & contributors
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.15;

/**
 * @dev Total staking amount information. One per Indexer.
 * Stake amount change need to be applied at next Era.
 */
struct StakingAmount {
    uint256 era;         // last update era
    uint256 valueAt;     // value at the era
    uint256 valueAfter;  // value to be refreshed from next era
}

/**
 * @dev Unbond amount information. One per request per Delegator.
 * Delegator can withdraw the unbond amount after the lockPeriod.
 */
struct UnbondAmount {
    address indexer;   // the indexer before delegate.
    uint256 amount;    // pending unbonding amount
    uint256 startTime; // unbond start time
}

enum UnbondType {
    Undelegation,
    Unstake,
    Commission,
    Merge
}

interface IStaking {
    function lockedAmount(address _delegator) external view returns (uint256);

    function unbondCommission(address _indexer, uint256 _amount) external;
}

// Copyright (C) 2020-2022 SubQuery Pte Ltd authors & contributors
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.15;

interface IStakingManager {
    function stake(address _indexer, uint256 _amount) external;

    function unstake(address _indexer, uint256 _amount) external;

    function slashIndexer(address _indexer, uint256 _amount) external;

    function getTotalStakingAmount(address _indexer) external view returns (uint256);

    function getAfterDelegationAmount(address _delegator, address _indexer) external view returns (uint256);
}

// Copyright (C) 2020-2022 SubQuery Pte Ltd authors & contributors
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.15;

contract Constants {
    uint256 public constant PER_MILL = 1e6;
    uint256 public constant PER_BILL = 1e9;
    uint256 public constant PER_TRILL = 1e12;
    address public constant ZERO_ADDRESS = address(0);
}

// Copyright (C) 2020-2022 SubQuery Pte Ltd authors & contributors
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.15;

library MathUtil {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x > y ? y : x;
    }

    function divUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x - 1) / y + 1;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 z
    ) internal pure returns (uint256) {
        return (x * y) / z;
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256) {
        if (x < y) {
            return 0;
        }
        return x - y;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}