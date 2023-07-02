// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenLocker is ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public totalUser;

    struct Users {
        bool status;
    }

    struct Locker {
        address tokenAddress;
        address beneficiary;
        uint256 startTime;
        uint256 totalAmount;
        uint256 claimedAmount;
        uint256 releaseInterval;
        uint256 releasePercentage;
        uint256 decimals;
    }

    Locker[] public lockers;
    mapping(address => Users) user;
    event TokensReleased(uint256 lockerIndex, uint256 releasedAmount);

    function createLocker(
        address _tokenAddress,
        address _beneficiary,
        uint256 _totalAmount,
        uint256 _releaseInterval,
        uint256 _releasePercentage,
        uint256 _decimals
    ) external nonReentrant {
        require(_tokenAddress != address(0), "Invalid token address");
        require(_beneficiary != address(0), "Invalid beneficiary address");
        require(_totalAmount > 0, "Invalid total amount");
        require(_releaseInterval > 0, "Invalid release interval");
        require(_releasePercentage > 0 && _releasePercentage <= 100, "Invalid release percentage");
        
        IERC20 token = IERC20(_tokenAddress);
        require(token.balanceOf(msg.sender) >= _totalAmount, "Token balance not enough");
        require(token.transferFrom(msg.sender, address(this), _totalAmount), "Token transfer failed");

        if(user[msg.sender].status == false){
            user[msg.sender].status = true;  
            totalUser += 1;          
        }

        Locker memory newLocker = Locker({
            tokenAddress: _tokenAddress,
            beneficiary: _beneficiary,
            startTime: block.timestamp,
            totalAmount: _totalAmount,
            claimedAmount: 0,
            releaseInterval: _releaseInterval,
            releasePercentage: _releasePercentage,
            decimals: _decimals
        });

        lockers.push(newLocker);
    }

    function releaseTokens(uint256 _lockerIndex) external nonReentrant {
        require(_lockerIndex < lockers.length, "Invalid locker index");

        Locker storage locker = lockers[_lockerIndex];
        require(locker.totalAmount != locker.claimedAmount, "All tokens have been claimed");
        require(msg.sender == locker.beneficiary, "Not the beneficiary");

        uint256 elapsedTime = block.timestamp.sub(locker.startTime);
        uint256 releaseCount = elapsedTime.div(locker.releaseInterval);
        require(releaseCount > 0, "No tokens to release yet");
        uint256 percents = 100;
        uint256 totalReleaseCount = percents.div(locker.releasePercentage);
        if (releaseCount > totalReleaseCount) {
            releaseCount = totalReleaseCount;
        }

        uint256 totalTokensToRelease = locker.totalAmount.mul(locker.releasePercentage).div(100);
        totalTokensToRelease = totalTokensToRelease.mul(releaseCount);
        uint256 tokensToRelease = totalTokensToRelease.sub(locker.claimedAmount);

        IERC20 token = IERC20(locker.tokenAddress);
        require(token.transfer(locker.beneficiary, tokensToRelease), "Token transfer failed");
        locker.claimedAmount = locker.claimedAmount.add(tokensToRelease);

        emit TokensReleased(_lockerIndex, tokensToRelease);
    }

    function getLockerCount() external view returns (uint256) {
        return lockers.length;
    }

    function getLockerIndexes(address _beneficiary) external view returns (uint256[] memory) {
        uint256[] memory indexes = new uint256[](lockers.length);
        uint256 count = 0;
        for (uint256 i = 0; i < lockers.length; i++) {
            if (lockers[i].beneficiary == _beneficiary) {
                indexes[count] = i;
                count++;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = indexes[i];
        }
        return result;
    }

    function getClaimableTokens(uint256 _lockerIndex) external view returns (uint256) {
        require(_lockerIndex < lockers.length, "Invalid locker index");

        Locker storage locker = lockers[_lockerIndex];
        uint256 elapsedTime = block.timestamp.sub(locker.startTime);
        uint256 releaseCount = elapsedTime.div(locker.releaseInterval);

        if (releaseCount == 0 || locker.totalAmount == locker.claimedAmount) {
            return 0;
        }

        uint256 percents = 100;
        uint256 totalReleaseCount = percents.div(locker.releasePercentage);
        if (releaseCount > totalReleaseCount) {
            releaseCount = totalReleaseCount;
        }

        uint256 totalTokensToRelease = locker.totalAmount.mul(locker.releasePercentage).div(100);
        totalTokensToRelease = totalTokensToRelease.mul(releaseCount);
        uint256 tokensToRelease = totalTokensToRelease.sub(locker.claimedAmount);

        return tokensToRelease;
    }

    function getTimeUntilNextRelease(uint256 _lockerIndex) external view returns (uint256) {
        require(_lockerIndex < lockers.length, "Invalid locker index");

        Locker storage locker = lockers[_lockerIndex];
        uint256 elapsedTime = block.timestamp.sub(locker.startTime);
        uint256 releaseCount = elapsedTime.div(locker.releaseInterval);
        uint256 nextReleaseTime = locker.startTime.add(locker.releaseInterval.mul(releaseCount.add(1)));

        uint256 percents = 100;
        uint256 totalReleaseCount = percents.div(locker.releasePercentage);

        if(releaseCount > totalReleaseCount || locker.totalAmount == locker.claimedAmount){
            return 0;
        }
        if (nextReleaseTime > block.timestamp) {
            return nextReleaseTime;
        } 
        return 0;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}