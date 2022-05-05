/**
 *Submitted for verification at polygonscan.com on 2022-05-05
*/

// File: DaoContracts/ILocker.sol


pragma solidity 0.8.0;

struct LockerState {
    uint256 currentLockingAmount;
    uint256 lockTime;
    uint256 delegatedTo;
    uint256 delegatedFrom;
}


interface ILocker {
    function getLockerState(address) external view returns(LockerState memory);

    function lock(uint256 amount, address lockedFor) external;

    function unlock(uint256 amount, address lockedFort) external;
}
// File: openzeppelin-solidity/contracts/utils/math/SafeMath.sol


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

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol


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

// File: DaoContracts/Locking.sol

pragma solidity 0.8.0;





contract Locker is ILocker {
    mapping (address => LockerState) lockersState;
    mapping (address => mapping(address => uint256)) public delegations;
    IERC20 public knightToken;
    address public treasury;
    uint256 constant public votingAllowedThreshold = 14 days;

    event Lock(address indexed addr, uint256 lockingAmount, uint256 totalLockingAmount);
    event Unlock(address indexed addr, uint256 unlockingAmount, uint256 penaltyAmount, uint256 totalRemainingLockingAmount);
    event Delegate(address indexed addr, address indexed lockedFor, uint256 amount);
    event Undelegate(address indexed addr, address indexed lockedFor, uint256 amount);


    constructor(address _knightToken, address _treasury) {
        knightToken = IERC20(_knightToken);
        treasury = _treasury;
    }


    function lock(uint256 lockingAmount, address lockedFor) external override {
        knightToken.transferFrom(msg.sender, address(this), lockingAmount);

        LockerState storage lockerState = lockersState[msg.sender];
        lockerState.currentLockingAmount += lockingAmount;
        lockerState.lockTime = block.timestamp;

        if (lockedFor != msg.sender) {
            require(lockedFor != address(0), "zero address is not allowed!");

            lockerState.delegatedFrom += lockingAmount;
            lockersState[lockedFor].delegatedTo += lockingAmount;
            delegations[msg.sender][lockedFor] += lockingAmount;
            emit Delegate(msg.sender, lockedFor, lockingAmount);
        }

        emit Lock(msg.sender, lockingAmount, lockerState.currentLockingAmount);
    }
    

    function unlock (uint256 unlockingAmount, address lockedFor) external override {
        LockerState storage lockerState = lockersState[msg.sender];
        require(lockerState.currentLockingAmount >= unlockingAmount, "current locking amount is less than unlocking amount!");

        if (lockedFor != msg.sender) {
            require(lockedFor != address(0), "zero address is not allowed!");
            require(lockerState.delegatedFrom >= unlockingAmount, "current delegated amount is less than unlocking amount!");
            require(delegations[msg.sender][lockedFor] >= unlockingAmount, "unlocking amount exceeds your delegation for this account!");

            lockerState.delegatedFrom -= unlockingAmount;
            lockersState[lockedFor].delegatedTo -= unlockingAmount;
            delegations[msg.sender][lockedFor] -= unlockingAmount;
            emit Undelegate(msg.sender, lockedFor, unlockingAmount);
        } else {
            require(lockerState.currentLockingAmount - lockerState.delegatedFrom >= unlockingAmount, "unlocking amount exceeds your locking amount!");
        }

        lockerState.currentLockingAmount -= unlockingAmount;
        uint256 payingAmount = unlockingAmount;
        uint256 penaltyAmount = 0;

        if (block.timestamp - lockerState.lockTime < votingAllowedThreshold) {
            penaltyAmount = unlockingAmount / 50; //// 2% penalty 

            if (penaltyAmount > 0) {
                payingAmount -= penaltyAmount;
                knightToken.transfer(treasury, penaltyAmount);
            }
        }

        if (payingAmount > 0) {
            knightToken.transfer(msg.sender, payingAmount);
        }
        emit Unlock(msg.sender, payingAmount, penaltyAmount, lockerState.currentLockingAmount);

    }

    function getLockerState(address addr) external override view returns(LockerState memory) {
        LockerState memory lockerState = lockersState[addr];
        return lockerState;
    }
}