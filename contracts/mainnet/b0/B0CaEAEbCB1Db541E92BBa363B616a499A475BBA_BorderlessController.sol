// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IStaking.sol";

contract BorderlessController is Ownable {
    mapping(uint256 => IStaking) _sdgs;

    constructor(address[] memory sdgs) {
        for (uint256 i = 0; i < 17; i++) {
            _sdgs[i + 1] = IStaking(sdgs[i]);
        }
    }

    function sdg(uint256 id) public view returns (IStaking) {
        return _sdgs[id];
    }

    function delegateAll(address[] memory strategies, uint256[] memory shares)
        external
        onlyOwner
    {
        for (uint256 i = 1; i <= 17; i++) {
            if (
                sdg(i).stakeBalanceByStatus(IStaking.StakeStatus.UNDELEGATED) >
                0
            ) {
                sdg(i).delegateAll(strategies, shares);
            }
        }
    }

    function addStrategy(address strategy) external onlyOwner {
        for (uint256 i = 1; i <= 17; i++) {
            sdg(i).addStrategy(strategy);
        }
    }

    function removeStrategy(address strategy) external onlyOwner {
        for (uint256 i = 1; i <= 17; i++) {
            sdg(i).removeStrategy(strategy);
        }
    }

    function addInitiative(
        string memory name,
        address controller,
        uint256 sdgId
    ) public onlyOwner returns (uint256 initiativeId) {
        return sdg(sdgId).addInitiative(name, controller);
    }

    function removeInitiative(uint256 initiativeId, uint256 sdgId)
        public
        onlyOwner
    {
        sdg(sdgId).removeInitiative(initiativeId);
    }

    function setInitiativesShares(
        uint256[] memory initiativeIds,
        uint256[] memory shares,
        uint256 sdgId
    ) public onlyOwner {
        sdg(sdgId).setInitiativesShares(initiativeIds, shares);
    }

    function addInitiativeBatch(
        string[] memory names,
        address[] memory controllers,
        uint256[] memory sdgIds
    ) public onlyOwner {
        require(
            names.length == controllers.length &&
                controllers.length == sdgIds.length,
            "Invalid input"
        );
        for (uint256 i = 0; i < names.length; i++) {
            addInitiative(names[i], controllers[i], sdgIds[i]);
        }
    }

    function removeInitiativeBatch(
        uint256[] memory initiativeIds,
        uint256[] memory sdgIds
    ) public onlyOwner {
        require(initiativeIds.length == sdgIds.length, "Invalid input");
        for (uint256 i = 0; i < initiativeIds.length; i++) {
            removeInitiative(initiativeIds[i], sdgIds[i]);
        }
    }

    function setInitiativesSharesBatch(
        uint256[][] memory initiativeIds,
        uint256[][] memory shares,
        uint256[] memory sdgIds
    ) public onlyOwner {
        require(
            initiativeIds.length == shares.length &&
                shares.length == sdgIds.length,
            "Invalid input"
        );
        for (uint256 i = 0; i < initiativeIds.length; i++) {
            setInitiativesShares(initiativeIds[i], shares[i], sdgIds[i]);
        }
    }

    function distributeRewards() external onlyOwner {
        for (uint256 i = 1; i <= 17; i++) {
            if (sdg(i).initiatives().length > 0 && sdg(i).totalRewards() > 0) {
                sdg(i).distributeRewards();
            }
        }
    }

    function setStakePeriodFees(
        uint256 threeMonthsFee,
        uint256 sixMonthsFee,
        uint256 oneYearFee
    ) external onlyOwner {
        for (uint256 i = 1; i <= 17; i++) {
            sdg(i).setStakePeriodFees(threeMonthsFee, sixMonthsFee, oneYearFee);
        }
    }

    function setFeeReceiver(address feeReceiver) external onlyOwner {
        for (uint256 i = 1; i <= 17; i++) {
            sdg(i).setFeeReceiver(feeReceiver);
        }
    }

    function stakeBalanceByStatus(IStaking.StakeStatus status)
        external
        view
        returns (uint256 balance)
    {
        for (uint256 i = 1; i <= 17; i++) {
            balance += sdg(i).stakeBalanceByStatus(status);
        }
        return balance;
    }

    function totalRewards() external view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 1; i <= 17; i++) {
            total += sdg(i).totalRewards();
        }
        return total;
    }

    function collectedRewards() external view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 1; i <= 17; i++) {
            total += sdg(i).collectedRewards();
        }
        return total;
    }

    function balances() external view returns (uint256[] memory sdgBalances) {
        sdgBalances = new uint256[](17);
        for (uint256 i = 1; i <= 17; i++) {
            sdgBalances[i - 1] =
                sdg(i).stakeBalanceByStatus(IStaking.StakeStatus.UNDELEGATED) +
                sdg(i).stakeBalanceByStatus(IStaking.StakeStatus.DELEGATED);
        }
        return sdgBalances;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/// Invalid balance to transfer. Needed `minRequired` but sent `amount`
/// @param sent sent amount.
/// @param minRequired minimum amount to send.
error InvalidAmount(uint256 sent, uint256 minRequired);

/// Strategies cannot be empty
error EmptyStrategies();

/// Strategies and shares lenghts must be equal.
/// @param strategiesLenght lenght of strategies array.
/// @param sharesLenght lenght of shares array.
error StrategiesAndSharesLengthsNotEqual(
    uint256 strategiesLenght,
    uint256 sharesLenght
);

/// Invalid shares sum. Needed `requiredSum` but sent `sum`
/// @param sum sum of shares.
/// @param requiredSum required sum of shares.
error InvalidSharesSum(uint256 sum, uint256 requiredSum);

/// Nothing to delegate
error NothingToDelegate();

/// SDG must not have any USDC left to finish the epoch.
/// @param usdcBalance balance of USDC.
error USDCBalanceIsNotZero(uint256 usdcBalance);

/// Strategy is not active or not exists.
/// @param strategyAddress address of strategy.
error InvalidStrategy(address strategyAddress);

/// Trying to exit a stake thats not owned by the sender.
/// @param sender sender address.
/// @param owner owner address.
/// @param stakeId stake id.
error NotOwnerOfStake(address sender, address owner, uint256 stakeId);

/// Nothing to unstake
error NothingToUnstake();

/// Stake is not delegated
/// @param stakeId stake id.
error StakeIsNotDelegated(uint256 stakeId);

/// Initiatives cannot be empty
error EmptyInitiatives();

/// Initiative ids and shares lenghts must be equal.
/// @param initiativeIdsLength lenght of initiative ids array.
/// @param sharesLenght lenght of shares array.
error InitiativesAndSharesLengthsNotEqual(
    uint256 initiativeIdsLength,
    uint256 sharesLenght
);

/// Initiative is not active
/// @param initiativeId id of initiative.
error InitiativeNotActive(uint256 initiativeId);

/// Initiatives shares neeed to be updated
error InitiativesSharesNeedToBeUpdated();

interface IStaking {
    event Stake(
        uint256 stakeId,
        uint256 amount,
        uint256 stakePeriod,
        address operator
    );
    event Exit(uint256 stakeId, uint256 amount);

    enum StakeStatus {
        UNDELEGATED,
        DELEGATED
    }

    enum StakePeriod {
        THREE_MONTHS,
        SIX_MONTHS,
        ONE_YEAR
    }

    struct StoredBalance {
        uint256 currentEpoch;
        uint256 currentEpochBalance;
        uint256 nextEpochBalance;
    }

    struct StakeInfo {
        StakeStatus status;
        uint256 amount;
        uint256 createdAt;
        StakePeriod stakePeriod;
        uint256 epoch;
        address[] strategies;
        uint256[] shares;
    }

    struct Initiative {
        uint256 id;
        string name;
        uint256 share;
        uint256 collectedRewards;
        address controller;
        bool active;
    }

    /// @dev Stake USDC tokens into SDG. Tokens are stored on the SDG until its delegation to strategies.
    /// @param amount of USDC to stake.
    /// @param period of stake.
    /// @param operator operator address.
    function stake(
        uint256 amount,
        StakePeriod period,
        address operator
    ) external;

    /// @dev Unstake USDC tokens from SDG. Tokens are returned to the sender.
    /// @param stakeId of stake to unstake.
    function exit(uint256 stakeId) external;

    function stakesByStatus(StakeStatus status)
        external
        view
        returns (uint256[] memory stakeIds);

    function stakeInfoByStakeId(uint256 stakeId)
        external
        view
        returns (StakeInfo memory);

    function storedBalanceByEpochId(uint256 epochId)
        external
        view
        returns (StoredBalance memory);

    function stakeBalanceByStatus(StakeStatus status)
        external
        view
        returns (uint256 balance);

    function computeFee(
        uint256 initialAmount,
        uint256 stakedAt,
        StakePeriod stakePeriod
    ) external view returns (uint256 finalAmount, uint256 totalFee);

    function feeByStakePeriod(StakePeriod period)
        external
        view
        returns (uint256 fee);

    function setStakePeriodFees(
        uint256 threeMonthsFee,
        uint256 sixMonthsFee,
        uint256 oneYearFee
    ) external;

    function setFeeReceiver(address) external;

    /// @dev Move USDC tokens to strategies by splitting the remaing balance and delegating it to each strategy.
    /// @param strategies of USDC to stake.
    /// @param shares of USDC to stake.
    function delegateAll(address[] memory strategies, uint256[] memory shares)
        external;

    function addStrategy(address strategy) external;

    function removeStrategy(address strategy) external;

    function activeStrategies() external view returns (address[] memory);

    function endEpoch() external;

    function totalRewards() external view returns (uint256);

    function collectedRewards() external view returns (uint256);

    function distributeRewards() external;

    function addInitiative(string memory name, address controller)
        external
        returns (uint256 initiativeId);

    function removeInitiative(uint256 initiativeId) external;

    function setInitiativesShares(
        uint256[] memory initiativeIds,
        uint256[] memory shares
    ) external;

    function initiatives() external view returns (Initiative[] memory);

    /// @dev Current epoch id
    /// @return Current epoch id
    function epoch() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}