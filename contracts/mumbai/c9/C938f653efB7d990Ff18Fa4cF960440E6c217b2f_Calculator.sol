// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Calculator {
    using SafeMath for uint256;

    uint public decimals = 18;
    uint public totalTokenReleased;
    uint public tokenRaiseTarget;

    mapping(uint => uint) public fundraiseToAmountRaised;
    mapping(uint => uint) public fundraiseToPricePerNFT;
    mapping(uint => uint) public fundraiseToDaily;

    uint public stakingAdjustment = 50;

    constructor(uint totalTokenReleased_, uint tokenRaiseTarget_) {
        totalTokenReleased = totalTokenReleased_;
        tokenRaiseTarget = tokenRaiseTarget_;
    }

    function setFundraise(uint fundraiseId, uint amount, uint pricePerNFT, uint daily) public {
        fundraiseToAmountRaised[fundraiseId] = amount;
        fundraiseToPricePerNFT[fundraiseId] = pricePerNFT;
        fundraiseToDaily[fundraiseId] = daily;
    }

    function setStakingAdjustment(uint stakingAdjustment_) public {
        stakingAdjustment = stakingAdjustment_;
    }

    function setTokenRaiseTarget(uint tokenRaiseTarget_) public {
        tokenRaiseTarget = tokenRaiseTarget_;
    }

    function setTotalTokenReleased(uint totalTokenReleased_) public {
        totalTokenReleased = totalTokenReleased_;
    }

    // how much NFT raise per fundraise
    function calculateNftRaise(uint fundraiseId) public view returns (uint) {
        return fundraiseToAmountRaised[fundraiseId].div(fundraiseToPricePerNFT[fundraiseId]);
    }

    // how much Token raise per fundraise
    function calculateTokenReleasedPerFundraise(uint fundraiseId) public view returns (uint) {
        return fundraiseToAmountRaised[fundraiseId].mul(totalTokenReleased).div(tokenRaiseTarget).div(10 ** decimals);
    }

    // how much Token raise per day
    function calculateDailyTokens(uint fundraiseId) public view returns (uint) {
        return calculateTokenReleasedPerFundraise(fundraiseId).div(fundraiseToDaily[fundraiseId]);
    }

    function calculateTokenPerNFT(uint remainDay) public view returns (uint) {
        return remainDay.mul(totalTokenReleased).div(tokenRaiseTarget);
    }

    // return the amount of tokens to (token to treasury, token to staker)
    function calculateTokensProportion(uint fundraiseId, uint tokenStaked) public view returns (uint, uint) {
        uint dailyTokens = calculateTotalTokenOfDay(fundraiseId); // 7871
        uint soldNFT = calculateTotalNftRaise(fundraiseId); // 5500

        uint tokensReleasedStakers = tokenStaked.mul(dailyTokens).div(soldNFT); // 1794 * 7871 / 5500 = 2568

        uint remainTokens = dailyTokens.sub(tokensReleasedStakers); // 7871 - 2568 = 5304
        uint tokensToTreasury = remainTokens.mul(stakingAdjustment).div(100); // 2652
        uint tokensToStaker = dailyTokens.sub(tokensToTreasury);
        return (tokensToTreasury, tokensToStaker);
    }

    function calculateTotalTokenOfDay(uint fundraiseId) public view returns (uint) {
        if (fundraiseId <= 1) {
            return calculateDailyTokens(1);
        }
        return calculateDailyTokens(fundraiseId).add(calculateTotalTokenOfDay(fundraiseId - 1));
    }

    function calculateTotalNftRaise(uint fundraiseId) public view returns (uint) {
        if (fundraiseId <= 1) {
            return calculateNftRaise(1);
        }
        return calculateNftRaise(fundraiseId).add(calculateTotalNftRaise(fundraiseId - 1));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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