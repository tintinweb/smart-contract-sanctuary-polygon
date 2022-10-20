// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IStaking.sol";

contract BorderlessCompound is Ownable {
    IERC20 _usdc;

    event Compound(address indexed sdg, uint256 amount);

    constructor(address usdc) {
        _usdc = IERC20(usdc);
    }

    function _stake(address sdg, uint256 amount) internal {
        _usdc.approve(sdg, amount);
        IStaking(sdg).stake(
            amount,
            IStaking.StakePeriod.ONE_YEAR,
            address(this)
        );

        emit Compound(sdg, amount);
    }

    function stakeAll(address[] memory sdgs, uint256[] memory amounts)
        external
        onlyOwner
    {
        require(
            sdgs.length == amounts.length,
            "Amounts and SDGs must be the same length"
        );
        for (uint256 i = 0; i < sdgs.length; i++) {
            _stake(sdgs[i], amounts[i]);
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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