/**
 *Submitted for verification at polygonscan.com on 2023-02-27
*/

// SPDX-License-Identifier: MIT


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

// File: dtcmtwp001.sol


pragma solidity ^0.8.0;


contract MaticDepositWithdraw {
    using SafeMath for uint256;

    address payable public owner;
    address payable public recipient;
    uint256 public balance;
    uint256 public withdrawalFee;
    uint256 public gasLimit;

    event Deposit(address indexed depositor, uint256 amount);
    event Withdrawal(address indexed recipient, uint256 amount, uint256 feeChanged, uint256 gasLimit);
    event OwnerWithdrawal(address indexed owner, uint256 amount);
    event Transfer(address indexed recipient, uint256 amount);

    struct WithdrawalInfo {
        address payable recipient;
        uint256 amount;
        uint256 fee;
    }

    struct TransferInfo {
        address payable recipient;
        uint256 amount;
    }

    WithdrawalInfo[] withdrawals;
    TransferInfo[] transfers;

    constructor(uint256 _withdrawalFee, uint256 _gasLimit) {
        owner = payable(msg.sender);
        recipient = owner;
        withdrawalFee = _withdrawalFee;
        balance = 0;
        gasLimit = _gasLimit;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }

    function deposit() public payable onlyOwner {
        require(msg.value > 0, "Deposit amount must be greater than zero.");
        balance = balance.add(msg.value);
        emit Deposit(msg.sender, msg.value);
    }
    function withdraw(uint256 _gasLimit) public onlyOwner {
        require(balance > 0, "Contract balance is zero.");
        uint256 amount = balance;
        uint256 fee = 0;
        if (withdrawalFee > 0) {
            fee = amount.mul(withdrawalFee).div(100);
            amount = amount.sub(fee);
            owner.transfer(fee);
        }
        balance = 0;
        (bool success,) = recipient.call{value: amount, gas: _gasLimit}("");
        require(success, "Transfer failed.");
        WithdrawalInfo memory withdrawal = WithdrawalInfo(recipient, amount, fee);
        withdrawals.push(withdrawal);
        emit Withdrawal(recipient, amount, withdrawalFee, gasLimit);
    }

    function ownerWithdrawal(uint256 amount) public onlyOwner {
        require(amount > 0, "Withdrawal amount must be greater than zero.");
        require(amount <= balance, "Insufficient balance for withdrawal.");
        owner.transfer(amount);
        balance = balance.sub(amount);
        emit OwnerWithdrawal(msg.sender, amount);
    }
function changeRecipient(address payable newRecipient) public onlyOwner {
        require(newRecipient != address(0), "Invalid recipient address.");
        recipient = newRecipient;
    }

    function getBalance() public view returns (uint256) {
        return balance;
    }

    function changeOwner(address payable newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid new owner address.");
        owner = newOwner;
    }

    function setWithdrawalFee(uint256 newWithdrawalFee) public onlyOwner {
        withdrawalFee = newWithdrawalFee;
    }

    function disableContract() public onlyOwner {
        selfdestruct(owner);
    }

function addTransfer(address payable _recipient, uint256 amount) public onlyOwner {
    require(_recipient != address(0), "Invalid recipient address.");
    require(amount > 0, "Transfer amount must be greater than zero.");
    require(amount <= balance, "Insufficient balance for transfer.");
    balance = balance.sub(amount);
    _recipient.transfer(amount);
    TransferInfo memory transfer = TransferInfo(_recipient, amount);
    transfers.push(transfer);
    emit Transfer(_recipient, amount);
}

    function getTransfer(uint256 index) public view returns (address payable, uint256, uint256) {
        require(index < withdrawals.length, "Invalid index.");
        WithdrawalInfo memory withdrawal = withdrawals[index];
        return (withdrawal.recipient, withdrawal.amount, withdrawal.fee);
    }

    function getTransferCount() public view returns (uint256) {
        return withdrawals.length;
    }

    receive() external payable {
        balance = balance.add(msg.value);
    }
}