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

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Declare the smart contract
contract PiggyBank {

    // For what do we use the libraries?
    using SafeMath for uint256;

    // Add variables for analytics
    uint256 public ethersIn;
    uint256 public ethersOut;

    // Variables for locking the deposit
    uint256 public lockTime;

    // Access
    address public owner;

    // Struct in order to make a deposit
    struct Deposit {
        uint256 _depositId;
        uint256 _amount; // Amount of tokens to be deposited
        address _from; // Who made the deposit
        uint256 _depositTime; // When the deposit was made?
        uint256 _unlockTime; // When the deposit will be unlocked?
    }

    // Create an array of deposits
    Deposit[] public deposits;

    // Giving initial values of our variables on deployment 
    constructor () {
        ethersIn = 0;
        ethersOut = 0;
        lockTime = 2 minutes;
        // The owner of this smart contract will be the deployer
        owner = msg.sender;
    }

    // Create a modifier
    // Functions marked with this modifier can be executed only if the "require" statement is checked
    modifier onlyOwner {
        // If the address that is calling a function is not the owner, an error will be thrown
        require(msg.sender == owner, "You are not the owner of the smart contract!");
        _;
    }

     // Allow the smart contract to receive ether
    receive() external payable {
    }

    // Deposit eth to the smart contract
    function depositEth() public payable onlyOwner{
        require(msg.value > 0, "You did'nt provide any funds");
        
        ethersIn = ethersIn.add(msg.value);

        // Get the total of deposits that were made
        uint256 depositId = deposits.length;

        // Create a new struct for the deposit
        Deposit memory newDeposit = Deposit(depositId, msg.value, msg.sender, block.timestamp, block.timestamp.add(lockTime));
        
        // Push the new deposit to the array
        deposits.push(newDeposit);
    }

    function withdrawEthFromDeposit(uint256 _depositId) public {
        require(block.timestamp >= deposits[_depositId]._unlockTime, "Unlock time not reached!");
        ethersOut = ethersOut.add(deposits[_depositId]._amount);
        payable(msg.sender).transfer(deposits[_depositId]._amount);
    }

    // Getter - functions that get a value
    // Get the amount of eth deposited in eth, not in Wei
    // 1 Eth = 1 * 10**18 Wei

    function getEthDeposited() public view returns (uint256) {
        return ethersIn.div(10**18);
    }

    function getEthWithdrawn() public view returns (uint256) {
        return ethersOut.div(10**18);
    }

    function getBalanceInWei() public view returns (uint256) {
        return address(this).balance;
    }

    function getDepositsLength() public view returns (uint256) {
        return deposits.length;
    }

    function getBalanceInEth() public view returns (uint256) {
        uint256 weiBalance = address(this).balance;
        uint256 ethBalance = weiBalance.div(10**18);
        return ethBalance;
    }

    // Setters - a function that, obviously, set a value

    // Set the unlock time of deposits to 10 minutes
    function setUnlockTimeToTenMinutes() public onlyOwner {
        lockTime = 10 minutes;
    }

    // Set the unlock time of deposits to 10 days
    function setUnlockTimeToTenDays() public onlyOwner {
        lockTime = 10 days;
    }

    // Set the unlock time of deposits to 5months
    function setUnlockTimeToTenMonths() public onlyOwner {
        lockTime = 5 * 30 days; // As we don't have "months" in solidity we will use 5 * 30 days
    }

    // Set the unlock time of deposits to 1 year
    function setUnlockTimeToOneYear() public onlyOwner {
        lockTime = 12 * 30 days; // As we don't have "years" in solidity we will use 12 * 30 days
    }

    // Set custom unlock time in minutes
    function setCustomUnlockTimeInMinutes(uint256 _minutes) public onlyOwner {
        uint256 _newLockTime = _minutes * 1 minutes;
        lockTime = _newLockTime;
    }

    // Set new owner
    function setNewOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}