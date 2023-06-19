/**
 *Submitted for verification at polygonscan.com on 2023-06-19
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


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

// File: HoneyExchange.sol


pragma solidity ^0.8.0;


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract HoneyExchange {
    using SafeMath for uint256;

    IERC20 private honeyToken;
    uint256 public honeyPotPrice = 7500000000000000;
    uint256 public honeyJarPrice = 15000000000000000;
    uint256 public honeyStashPrice = 30000000000000000;
    uint256 public exchangeRate = 6666666;
    address private owner;

    modifier onlyOwner {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    constructor(address honeyTokenAddress) {
        honeyToken = IERC20(honeyTokenAddress);
        owner = msg.sender;
    }
    function buyHnyWithExchangeRate(uint256 ethAmount) payable public {
        uint256 tokenAmount = ethAmount.mul(exchangeRate);
        require(tokenAmount <= honeyToken.balanceOf(address(this)), "Contract does not have enough tokens");
        honeyToken.transfer(msg.sender, tokenAmount);
    }
    function buyHoneyPot() payable public {
        require(msg.value == honeyPotPrice, "Incorrect amount of Ether sent");
        uint256 tokenAmount = honeyPotPrice.mul(exchangeRate);
        require(tokenAmount <= honeyToken.balanceOf(address(this)), "Contract does not have enough tokens");
        honeyToken.transfer(msg.sender, tokenAmount);
    }
    function buyHoneyJar() payable public {
        require(msg.value == honeyJarPrice, "Incorrect amount of Ether sent");
        uint256 tokenAmountBefore = honeyJarPrice.mul(exchangeRate);
        uint256 bonusTokens = tokenAmountBefore.mul(10).div(100);
        uint256 tokenAmount = tokenAmountBefore.add(bonusTokens);
        require(tokenAmount <= honeyToken.balanceOf(address(this)), "Contract does not have enough tokens");
        honeyToken.transfer(msg.sender, tokenAmount);
    }
    function buyHoneyStash() payable public {
        require(msg.value == honeyStashPrice, "Incorrect amount of Ether sent");
        uint256 tokenAmountBefore = honeyStashPrice.mul(exchangeRate);
        uint256 bonusTokens = tokenAmountBefore.mul(20).div(100);
        uint256 tokenAmount = tokenAmountBefore.add(bonusTokens);
        require(tokenAmount <= honeyToken.balanceOf(address(this)), "Contract does not have enough tokens");
        honeyToken.transfer(msg.sender, tokenAmount);
    }
    function setExchangeRate(uint256 newRate) public onlyOwner {
        exchangeRate = newRate;
    }
    function setHoneyPotPrice(uint256 newPrice) public onlyOwner {
        honeyPotPrice = newPrice;
    }
    function setHoneyJarPrice(uint256 newPrice) public onlyOwner {
        honeyJarPrice = newPrice;
    }
    function setHoneyStashPrice(uint256 newPrice) public onlyOwner {
        honeyStashPrice = newPrice;
    }
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    function withdrawHny() public onlyOwner {
        uint256 balance = honeyToken.balanceOf(address(this));
        require(balance > 0, "Contract does not have any tokens to withdraw");
        honeyToken.transfer(owner, balance);
    }
}