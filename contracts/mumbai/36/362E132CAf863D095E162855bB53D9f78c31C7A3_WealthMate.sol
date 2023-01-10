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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
@author Mbazu Ifeanyichukwu Daniel
@dev Grandida bank

*/

contract WealthMate {
    using SafeMath for uint;

    // State Variables
    address public owner; // address of the owner of the bank

    // Mapping to store customer balances
    mapping(address => uint) public balances;

    // Events
    event Deposit(address indexed customerAddress, uint depositAmount); // emitted when a customer deposits tokens
    event Withdraw(
        address indexed customerAddress,
        uint withdrawAmount,
        uint newBalance
    ); // emitted when a customer withdraws tokens
    event Transfer(address from, address to, uint transferAmount); // emitted when a customer transfers tokens to another account

    // MODIFIERS
    modifier onlyOwner() {
        // modifier to restrict certain functions to only be callable by the owner of the bank
        require(msg.sender == owner, "You're not the owner of the bank");
        _;
    }

    // Constructor
    constructor() {
        owner = msg.sender; // set the owner of the bank to the address that deployed the contract
    }

    // Fallback and Receive function
    receive() external payable {} // allow the contract to receive ether

    fallback() external payable {} // allow the contract to receive tokens

    /// @dev Get balance of customer
    function getCustomerBalance() external view returns (uint) {
        // return the balance of the customer calling the function
        return balances[msg.sender];
    }

    /// @notice deposit token into the bank
    function depositToken() external payable {
        // you cannot deposit 0 amount
        require(msg.value != 0, "You don't have enough token to deposit");

        // Use SafeMath's add function to prevent overflow
        balances[msg.sender] = balances[msg.sender].add(msg.value);

        // log event of the deposit made
        emit Deposit(msg.sender, msg.value);
    }

    /// @dev customer withdraw token back to account
    function withdrawToken(
        address payable receiver,
        uint withdrawAmount
    ) external {
        // check that the customer has sufficient funds
        require(withdrawAmount <= balances[msg.sender], "insufficient funds");

        // Use SafeMath's sub function to prevent underflow
        balances[msg.sender] = balances[msg.sender].sub(withdrawAmount);

        // transfer token from the bankAddress to the customer
        receiver.transfer(withdrawAmount);

        // log event of the withdrawal made
        emit Withdraw(msg.sender, withdrawAmount, balances[msg.sender]);
    }

    /// @dev send token to another account from your bank balances
    function transferToken(
        address to,
        uint transferAmount
    ) external payable returns (bool) {
        // check that the customer has sufficient funds
        require(balances[msg.sender] >= transferAmount, "insufficient funds");

        // Use SafeMath's sub function to prevent underflow
        balances[msg.sender] = balances[msg.sender].sub(transferAmount);

        // transfer token from the bankAddress to the customer
        (bool success, ) = to.call{value: transferAmount}("");
        require(success, "Call failed");

        // add transferred amount to receivers account
        balances[to] = balances[to].add(transferAmount);

        // log event of the transfer made
        emit Transfer(msg.sender, to, transferAmount);
        return true;
    }
}