// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IStaking.sol";
import "./StakePlan.sol";

contract Deposit is ReentrancyGuard {
    using SafeMath for uint256;


    address public beneficiary;

    IERC20 public token;

    IStaking public stakingContract;

    address public stakingContractAddress;

    uint256 public harvested;
    
    uint256 public amount;

    uint256 public depositDate;

    uint256 public harvestInterval;

    address public owner;

    bool public closed;

    uint256 public lockedDuration;
    uint256 public unstakePenaltyDuration;
    uint256 public unstakePenaltyRateBP;
    StakePlanContext.StakePlan public stakePlan;

    uint256 public interestPayIndex;
    uint256[] public interestPayDates;
    uint256[] public interestPayAmounts;
    uint256 public interestLastPaymentTime;

    constructor(
        address _owner,
        address _tokenAddress,
        address _beneficiary,
        uint256 _amount,
        StakePlanContext.StakePlan _stakePlan,
        uint256 _interestRate,
        uint256 _lockedDuration,
        uint256 _unstakePenaltyDuration,
        uint256 _unstakePenaltyRateBP,
        uint256 _harvestInterval
    ) {
        stakingContract = IStaking(msg.sender);
        stakingContractAddress = msg.sender;

        owner = _owner;
        token = IERC20(_tokenAddress);        
        beneficiary = _beneficiary;
        amount = _amount;
        stakePlan = _stakePlan;
        depositDate = block.timestamp;
        unstakePenaltyDuration = _unstakePenaltyDuration;
        unstakePenaltyRateBP = _unstakePenaltyRateBP;
        lockedDuration = _lockedDuration;
        harvestInterval = _harvestInterval;

        addInterestAllocation((_amount.mul(_interestRate).div(1000000)), depositDate);
        addInterestAllocation((_amount.mul(_interestRate).div(1000000)), depositDate);
        addInterestAllocation((_amount.mul(_interestRate).div(1000000)), depositDate);
        addInterestAllocation((_amount.mul(_interestRate).div(1000000)), depositDate);
    }

    function addInterestAllocation(uint256 _amount, uint256 _date) internal nonReentrant onlyStakingContract {
        interestPayAmounts.push(_amount);
        interestPayDates.push(_date);
    }

    function lockedUntilDate() public view returns (uint256) {
        return depositDate.add(lockedDuration);
    }

    function unstakePenaltyUntilDate() public view returns (uint256) {
        if (stakePlan == StakePlanContext.StakePlan.FLEXI_PLAN) {
            return depositDate.add(unstakePenaltyDuration);
        }
        return 0;
    }

    function closeDeposit() external nonReentrant onlyStakingContract { 
        require(!closed, "Deposit is already closed");
        require(
            lockedUntilDate() <= block.timestamp,
            "Staking deposit is still locked"
        );
        if (unstakePenaltyUntilDate() < block.timestamp) {
            token.transfer(beneficiary, amount);
        } else {
            uint256 penalty = amount.mul(unstakePenaltyRateBP).div(1000000);
            token.transfer(beneficiary, amount.sub(penalty));
            token.transfer(stakingContract.getPenaltyWallet(),penalty);            
        }     
        closed = true;
    }

    function forceCloseDeposit() external nonReentrant onlyStakingContract { 
        require(!closed, "Deposit is already closed");
        token.transfer(beneficiary, amount);
        closed = true;
    }

    function calculateHarvest() public view returns(uint256 _interest) {
        for(uint i = 0; i<interestPayDates.length; i++) {
            if (interestPayDates[i] <= block.timestamp && interestPayDates[i] > interestLastPaymentTime) {
                _interest = _interest.add(interestPayAmounts[i]);
            }
        }
        return _interest;
    }

    function getHarvested() public view returns(uint256 _harvested) {
        return harvested;
    }

    function harvestDeposit() external nonReentrant onlyStakingContract returns (uint256 _amount) {
        uint256 interest = this.calculateHarvest();
        require(interest>0, "Nothing to harvest");        
        interestLastPaymentTime = block.timestamp;
        harvested = harvested.add(interest);
        return interest;
    }

    function canCloseDeposit() public view returns(bool _canClose) {
        return (lockedUntilDate() <= block.timestamp && !closed);
    }

    modifier onlyStakingContract() {
        require(
            stakingContractAddress == msg.sender,
            "Only the staking contract can call this function."
        );
        _;
    }     
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IStaking {

    function getPenaltyWallet() external returns(address _penaltyWallet);

    function depositHarvest(address _beneficiary, uint256 _amount) external;   
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;
contract StakePlanContext {
    enum StakePlan {
        FLEXI_PLAN,
        LOCKED_PLAN
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./Deposit.sol";
import "./StakePlan.sol";

contract Staking is
    ReentrancyGuard,
    Ownable,
    Pausable {
    using SafeMath for uint256;
    
    IERC20 public token;

    mapping(uint256 => address) public deposits;
    mapping(address => bool) public isDeposit;

    uint256 public depositIndex;
    address public penaltyWallet;
    address public harvestWallet;

    uint256 public flexiPlanInterestRateBP;
    uint256 public lockedPlanInterestRateBP;

    uint256 public flexiPlanLockedDuration;
    uint256 public lockedPlanLockedDuration;

    uint256 public flexiPlanUnstakePenaltyDuration;
    uint256 public flexiPlanUnstakePenaltyRateBP;

    uint256 public flexiPlanHarvestInterval;
    uint256 public lockedPlanHarvestInterval;

    uint256 public flexiPlanEpochTokenAmount;
    uint256 public lockedPlanEpochTokenAmount;


    uint256 public epochFlexiTokenLimit;
    uint256 public epochLockedTokenLimit;
    uint256 public epochStartTime;
    uint256 public epochEndTime;

    event DepositCreated(
        address indexed beneficiary,
        address indexed depositContractAddress, 
        uint256 amount,
        StakePlanContext.StakePlan stakePlan
        );

    event DepositClosed(
        address indexed beneficiary,
        address indexed depositContractAddress,
        uint256 amount,
        StakePlanContext.StakePlan stakePlan
    );

    event DepositHarvest(
        address indexed beneficiary,
        address indexed depositContractAddress,
        uint256 amount,
        StakePlanContext.StakePlan stakePlan
    );    

    modifier onlyDeposit() {
        require(
            isDeposit[msg.sender],
            "SR: Only a deposit can call this function"
        );
        _;
    }

    function setEpoch(
        uint256 _epochFlexiTokenLimit,
        uint256 _epochLockedTokenLimit,
        uint256 _epochStartTime,
        uint256 _epochEndTime,
        uint256 _currentFlexiTokenAmount,
        uint256 _currentLockedTokenAmount
    )
        external
        onlyOwner
    {
        epochFlexiTokenLimit = _epochFlexiTokenLimit;
        epochLockedTokenLimit = _epochLockedTokenLimit;
        epochStartTime = _epochStartTime;
        epochEndTime = _epochEndTime;
        flexiPlanEpochTokenAmount = _currentFlexiTokenAmount;
        lockedPlanEpochTokenAmount = _currentLockedTokenAmount;
    }

    function configureStaking(
        address _tokenAddress,
        address _penaltyWallet,
        address _harvestWallet,

        uint256 _flexiPlanInterestRateBP,
        uint256 _lockedPlanInterestRateBP,

        uint256 _flexiPlanLockedDuration,
        uint256 _lockedPlanLockedDuration,

        uint256 _flexiPlanUnstakePenaltyDuration,
        uint256 _flexiPlanUnstakePenaltyRateBP,

        uint256 _flexiPlanHarvestInterval,
        uint256 _lockedPlanHarvestInterval
    )
        external
        onlyOwner
    {
        token = IERC20(_tokenAddress);
        penaltyWallet = _penaltyWallet;
        harvestWallet = _harvestWallet;

        flexiPlanInterestRateBP = _flexiPlanInterestRateBP;
        lockedPlanInterestRateBP = _lockedPlanInterestRateBP;

        flexiPlanLockedDuration = _flexiPlanLockedDuration;
        lockedPlanLockedDuration = _lockedPlanLockedDuration;

        flexiPlanUnstakePenaltyDuration = _flexiPlanUnstakePenaltyDuration;
        flexiPlanUnstakePenaltyRateBP = _flexiPlanUnstakePenaltyRateBP;

        flexiPlanHarvestInterval = _flexiPlanHarvestInterval;
        lockedPlanHarvestInterval = _lockedPlanHarvestInterval;

    }

    function openDeposit(
        uint256 _amount,
        StakePlanContext.StakePlan _stakePlan
    ) external whenNotPaused nonReentrant {
        require(address(token) != address(0), "Token address is not set");
        require(_amount > 0, "Cannot stake 0");
        require(block.timestamp > epochStartTime && block.timestamp < epochEndTime, "Staking epoch is not open");
        require(
            token.allowance(msg.sender, address(this)) >= _amount,
            "Allowance should be greater or equal to the amount staked"
        );
        Deposit _deposit;
        if (_stakePlan == StakePlanContext.StakePlan.FLEXI_PLAN) {            
            _deposit = new Deposit(
                owner(),
                address(token),
                msg.sender,
                _amount,
                _stakePlan,
                flexiPlanInterestRateBP,
                flexiPlanLockedDuration,
                flexiPlanUnstakePenaltyDuration,
                flexiPlanUnstakePenaltyRateBP,
                flexiPlanHarvestInterval
            );
            flexiPlanEpochTokenAmount = flexiPlanEpochTokenAmount.add(_amount);
            require(flexiPlanEpochTokenAmount<epochFlexiTokenLimit, "Token limit is exceeded");
        } else {            
            _deposit = new Deposit(
                owner(),
                address(token),
                msg.sender,
                _amount,
                _stakePlan,
                lockedPlanInterestRateBP,
                lockedPlanLockedDuration,
                0,
                0,
                lockedPlanHarvestInterval
            );
            lockedPlanEpochTokenAmount = lockedPlanEpochTokenAmount.add(_amount);
            require(lockedPlanEpochTokenAmount<epochLockedTokenLimit, "Token limit is exceeded");
        }
        token.transferFrom(msg.sender, address(_deposit), _amount);

        require(
            token.balanceOf(address(_deposit)) == _amount,
            "Transfer not completed"
        );

        deposits[depositIndex] = address(_deposit);
        isDeposit[address(_deposit)] = true;
        depositIndex++;

        emit DepositCreated(
            msg.sender,
            address(_deposit),
            _amount,
            _stakePlan
        );
    }

    function canCloseDeposit(address _depositContractAddress) public view returns(bool _canClose) {
        require(isDeposit[_depositContractAddress], "The address is not a deposit");
        Deposit deposit = Deposit(_depositContractAddress);
        return deposit.canCloseDeposit();
    }

    function closeDeposit(address _depositContractAddress) external whenNotPaused nonReentrant {
        require(isDeposit[_depositContractAddress], "The address is not a deposit");
        Deposit deposit = Deposit(_depositContractAddress);
        require(deposit.beneficiary() == msg.sender, "Only the beneficiary can close the deposit");
        deposit.closeDeposit();
        emit DepositClosed(
            deposit.beneficiary(),
            _depositContractAddress,
            deposit.amount(),
            deposit.stakePlan()
        );
    }

    function harvestDeposit(address _depositContractAddress) external whenNotPaused nonReentrant {
        require(isDeposit[_depositContractAddress], "The address is not a deposit");
        Deposit deposit = Deposit(_depositContractAddress);
        require(deposit.beneficiary() == msg.sender, "Only the beneficiary can harvest the deposit");
        uint256 amount = deposit.harvestDeposit();
        token.transferFrom(harvestWallet, deposit.beneficiary(), amount);
        emit DepositHarvest(
            deposit.beneficiary(),
            _depositContractAddress,
            amount,
            deposit.stakePlan()
        );
    }

    function checkHarvestDeposit(address _depositContractAddress) public view returns(uint256 _amount) {
        require(isDeposit[_depositContractAddress], "The parameter is not a deposit");
        Deposit deposit = Deposit(_depositContractAddress);
        require(deposit.beneficiary() == msg.sender, "Only the beneficiary can harvest the deposit");
        uint256 amount = deposit.calculateHarvest();
        return amount;
    }

    function getHarvestedDeposit(address _depositContractAddress) public view returns(uint256 _harvested) {
        require(isDeposit[_depositContractAddress], "The parameter is not a deposit");
        Deposit deposit = Deposit(_depositContractAddress);
        require(deposit.beneficiary() == msg.sender, "Only the beneficiary can harvest the deposit");
        uint256 harvested = deposit.getHarvested();
        return harvested;
    }

    function forceCloseStaking(address _depositContractAddress) external onlyOwner nonReentrant {
        require(isDeposit[_depositContractAddress], "The address is not a deposit");
        Deposit deposit = Deposit(_depositContractAddress);
        deposit.forceCloseDeposit();
        emit DepositClosed(
            deposit.beneficiary(),
            _depositContractAddress,
            deposit.amount(),
            deposit.stakePlan()
        );
    }    

    function getPenaltyWallet() public view returns(address _penaltyWallet) {
        return penaltyWallet;
    }
}