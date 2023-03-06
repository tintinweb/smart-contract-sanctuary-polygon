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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Stoppable.sol";

contract Loan is Stoppable {
  using SafeMath for uint256;

  enum Status {
    PENDING,
    ACTIVE,
    RESOLVED
  }

  struct Loans {
    uint fullAmount;
    uint amount;
    uint interest;
    uint ID;
    address lender;
    address borrower;
    Status status;
    uint requiredDeposit;
  }

  uint public loanId;
  event LogLoanCreation(address indexed _lender, uint indexed _loanId);
  event LogDeposit(address indexed _borrower, uint indexed _depositAmount);
  event LogRetrieved(uint indexed _loanID, address indexed _borrower, uint indexed _amountRetrieved);
  event LogPaid(address indexed _borrower, uint indexed _loanID, uint indexed _paidBack);
  event LogKilledWithdraw(address indexed owner, uint indexed contractAmount);

  mapping(uint256 => Loans) public loans;

  modifier paidDeposit(uint _loanId) {
    require(loans[_loanId].status == Status.ACTIVE, "This loan is not active");
    _;
  }

  constructor() {
    loanId = 1;
  }

  function createLoan(
    uint _interest,
    address _borrower,
    uint _depositPercentage
  ) external payable whenRunning whenAlive returns (bool) {
    require(_depositPercentage <= 100, "Deposit Percentage cannot exceed 100");
    require(_borrower != address(0x0), "Borrower's address cannot be 0");
    require(msg.value > 0, "Loan must have an associated Value");
    emit LogLoanCreation(msg.sender, loanId);

    uint256 depositPercentage = msg.value.mul(_depositPercentage).div(100);
    uint256 fullAmount = msg.value.add(_interest);

    loans[loanId] = Loans({
      fullAmount: fullAmount,
      amount: msg.value,
      interest: _interest,
      ID: loanId,
      lender: msg.sender,
      borrower: _borrower,
      status: Status.PENDING,
      requiredDeposit: depositPercentage
    });

    loanId = loanId + 1;
    return true;
  }

  function payLoanDeposit(uint _loanId) external payable whenRunning whenAlive {
    require(loans[_loanId].status == Status.PENDING, "Loan status must be PENDING");
    require(msg.value == loans[_loanId].requiredDeposit, "You must deposit the right amount");
    require(msg.sender == loans[_loanId].borrower, "You must be the assigned borrower for this loan");
    loans[_loanId].status = Status.ACTIVE;
    loans[_loanId].fullAmount = loans[_loanId].fullAmount.sub(loans[_loanId].requiredDeposit);
    (bool success, ) = loans[_loanId].lender.call{value: msg.value}("");
    require(success, "Error: Transfer failed.");
    emit LogDeposit(msg.sender, msg.value);
  }

  function payBackLoan(uint _loanId) public payable whenRunning whenAlive {
    require(msg.sender == loans[_loanId].borrower, "You must be the assigned borrower for this loan");
    require(msg.value == (loans[_loanId].fullAmount), "You must pay the full loan amount includinginterest");
    require(loans[_loanId].status == Status.ACTIVE, "Loan status must be ACTIVE");

    loans[_loanId].status = Status.RESOLVED;
    (bool success, ) = loans[_loanId].lender.call{value: msg.value}("");
    require(success, "Error: Transfer failed.");

    emit LogPaid(msg.sender, _loanId, msg.value);
  }

  function retrieveLoanFunds(uint _loanId) public payable whenRunning whenAlive paidDeposit(_loanId) {
    require(msg.sender == loans[_loanId].borrower, "Requires the borrower of that loan");
    require(loans[_loanId].amount != 0, "There are no funds to retrieve");
    uint256 loanAmount = loans[_loanId].amount;

    loans[_loanId].amount = 0;
    (bool success, ) = msg.sender.call{value: loanAmount}("");
    require(success, "Error: Transfer failed.");

    emit LogRetrieved(_loanId, msg.sender, loanAmount);
  }

  function retrieveLoans(
    uint _loanId
  )
    public
    view
    whenRunning
    whenAlive
    returns (
      uint fullAmount,
      uint amount,
      uint interest,
      address lender,
      address borrower,
      uint status,
      uint requiredDeposit
    )
  {
    fullAmount = loans[_loanId].fullAmount;
    amount = loans[_loanId].amount;
    interest = loans[_loanId].interest;
    lender = loans[_loanId].lender;
    borrower = loans[_loanId].borrower;
    status = uint(loans[_loanId].status);
    requiredDeposit = loans[_loanId].requiredDeposit;
    return (fullAmount, amount, interest, lender, borrower, status, requiredDeposit);
  }

  function withdrawWhenKilled() public whenKilled onlyOwner {
    require(address(this).balance > 0, "Error: The contract is empty");
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Error: Transfer failed.");
    emit LogKilledWithdraw(msg.sender, address(this).balance);
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ownable {
  address private owner;

  event OwnershipTransferred(address newOwner);

  /*
    This constructor function sets the initial deployer
    to the owner, constructors executes once on deployment
    */
  constructor() {
    owner = msg.sender;
  }

  /*
    Checks to see if the msg.sender is the owner,
    this mofidier is used on functions like kill(),
    withdrawWhenKilled(), Stop() and Resume().
    Authoritative functions should be limited to the owner,
    and no publicly.
    */
  modifier onlyOwner() {
    require(msg.sender == owner, "Error: msg.sender must be owner");
    _;
  }

  /*
    This read only function simply retrieves the owners address.
    */
  function getOwner() public view returns (address _owner) {
    return owner;
  }

  /*
    Allows for the current owner to set a new owner.
    */
  function setOwner(address newOwner) public onlyOwner returns (bool success) {
    require(newOwner != address(0x0), "Error: Address cannot be 0");
    emit OwnershipTransferred(newOwner);
    owner = newOwner;
    return true;
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract Stoppable is Ownable {
  bool private stopped;
  bool private killed;

  event LogStopped(address _owner);
  event LogResumed(address _owner);
  event LogKilled(address _killer);

  /*
    The constructor function instantiates the value
    for the state variables stopped and killed to false.
    */
  constructor() {
    stopped = false;
    killed = false;
  }

  /*
    This modifier checks if the contract is killed.
    WithdrawWhenKilled() uses this modifier so that it
    can only be called in the event that the contract
    has been killed, and not before.
    */
  modifier whenKilled() {
    require(killed, "Contract is alive");
    _;
  }

  /*
    This modifier checks to see if the contract is alive,
    as long as this is the case, functions will run as
    expected.
    */
  modifier whenAlive() {
    require(!killed, "Contract is dead");
    _;
  }

  /*
    This modifier checks to see if the contract has
    been stopped or not. As long as whenRunning reamins
    true, functions will run as expected.
    */
  modifier whenRunning() {
    require(!stopped, "Contract is paused.");
    _;
  }

  /*
    This mofidier checks that the contract is paused.
    Functions using this modifier may continue to function
    when the contracts state has been Stopped.
    Functions like Resume() and Kill() may be
    called during this state.
    */
  modifier whenPaused() {
    require(stopped, "Contract is running");
    _;
  }

  /*
    This function allows the owner to freeze
    the use of functions labelled with the whenRunning
    modifier. In the case of an emergency where the use
    of the DApp must be limited, this can be called by the
    owner to limit damage and usage until the issue is resolved.
    */
  function stop() public onlyOwner whenAlive whenRunning {
    stopped = true;
    emit LogStopped(msg.sender);
  }

  /*
    This function allows the owner to resume
    the use of functions that have been previously
    stopped. In the case that things were resolved
    in the time that the contract was stopped, we
    can then resume the contract and have it run again.
    */
  function resume() public onlyOwner whenAlive whenPaused {
    stopped = false;
    emit LogResumed(msg.sender);
  }

  /*
    This function is a two step process to prevent
    an irreversible mistake. This kill function
    essentially puts the contract into an un-resumable
    state, that when called, cannot be undone. For this
    to successfully execute, the contract must be paused first.
    The only function that can be utilised in the event of the
    contract being killed is the withdrawWhenKilled function that
    is only accessible to the owner.
    */
  function kill() public onlyOwner whenAlive whenPaused {
    killed = true;
    emit LogKilled(msg.sender);
  }
}