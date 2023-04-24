/**
 *Submitted for verification at polygonscan.com on 2023-04-23
*/

// SPDX-License-Identifier: MIT
// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/Fiverr/parifinance/test2.sol


pragma solidity ^0.8.0;



contract CryptoLending {

    uint256 public constant BASE = 10**18;
    uint256 public constant DIVIDEND_PERCENTAGE = 10;
    uint256 public constant CASHBACK_PERCENTAGE = 15;
    uint256 public constant APR = 12;
    uint256 public constant MAX_LTV = 30;
    uint256 public constant LIQUIDATION_THRESHOLD = 49;
    uint256 public constant WITHDRAWAL_FEE = 39;
    uint256 public constant BORROWING_FEE = 39;
    uint256 public constant BORROWING_UTILIZATION_THRESHOLD = 80;
    uint256 public constant BORROWING_INTEREST_RATE = 12;
    uint256 public constant BORROWING_INTEREST_RATE_THRESHOLD = 30;
    uint256 public constant MONTHLY_DIVIDEND_PERCENTAGE = 10;

    address public owner;
    uint256 public totalFunds;
    uint256 public totalLoans;
    uint256 public totalWithdrawals;
    uint256 public totalBorrowings;
    uint256 public dividendPool;
    uint256 public borrowingUtilization;

    AggregatorV3Interface public priceFeed;

    struct Token {
        address tokenAddress;
        uint256 balance;
    }

    struct Loan {
        uint256 id;
        address borrower;
        uint256 amount;
        uint256 collateral;
        uint256 interest;
        uint256 startTimestamp;
        uint256 endTimestamp;
        bool active;
    }

    mapping(address => Token) public tokens;
    mapping(address => uint256) public withdrawals;
    mapping(address => uint256) public borrowings;
    mapping(address => uint256) public dividends;
    mapping(address => uint256) public dividendWithdrawals;
    mapping(address => uint256) public borrowingCollateral;
    mapping(address => uint256) public borrowingDebt;
    mapping(address => Loan[]) public loansByBorrower;
    mapping(uint256 => Loan) public loansById;

    event NewDeposit(address indexed from, address indexed tokenAddress, uint256 amount);
    event NewWithdrawal(address indexed from, address indexed tokenAddress, uint256 amount, uint256 fee);
    event NewLoan(address indexed borrower, uint256 amount, uint256 collateral);
    event LoanRepayed(uint256 indexed loanId, address indexed borrower, uint256 amount, uint256 interest);
    event DividendPaid(address indexed to, uint256 amount);
    event CashbackPaid(address indexed to, uint256 amount);

    constructor() {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada);
        tokens[0x55d398326f99059fF775485246999027B3197955] = Token(0x55d398326f99059fF775485246999027B3197955, 0);
        tokens[0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d] = Token(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d, 0);
        tokens[0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3] = Token(0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3, 0);
    }

function deposit(address tokenAddress, uint256 amount) public {
    require(amount > 0, "Amount must be greater than 0");
    Token storage token = tokens[tokenAddress];
    IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
    token.balance += amount;
    totalFunds += amount;

    emit NewDeposit(msg.sender, tokenAddress, amount);
}

function withdraw(address tokenAddress, uint256 amount) public {
    require(amount > 0, "Amount must be greater than 0");
    Token storage token = tokens[tokenAddress];
    require(token.tokenAddress != address(0), "Invalid token address");
    require(amount <= token.balance, "Insufficient balance");

    uint256 fee = (amount * WITHDRAWAL_FEE) / BASE;
    uint256 netAmount = amount - fee;

    IERC20(tokenAddress).transfer(msg.sender, netAmount);
    token.balance -= amount;
    totalWithdrawals += netAmount;

    emit NewWithdrawal(msg.sender, tokenAddress, netAmount, fee);
}

function borrow(address tokenAddress, uint256 amount, address collateralToken, uint256 collateralAmount) public {
    require(amount > 0, "Amount must be greater than 0");
    Token storage token = tokens[tokenAddress];
    require(token.tokenAddress != address(0), "Invalid token address");

    uint256 maxCollateral = (token.balance * MAX_LTV) / BASE;
    require(collateralAmount > 0 && collateralAmount <= maxCollateral, "Invalid collateral amount");

    IERC20(tokenAddress).transfer(msg.sender, amount);
    token.balance -= amount;
    totalBorrowings += amount;

    uint256 borrowingInterest = APR;
    if (borrowingUtilization > BORROWING_UTILIZATION_THRESHOLD) {
        borrowingInterest = BORROWING_INTEREST_RATE_THRESHOLD;
    }

    uint256 borrowingFee = (amount * borrowingInterest * BORROWING_FEE) / (BASE * 100);
    uint256 interest = (amount * borrowingInterest) / 100;

    Loan memory loan = Loan({
        id: loansByBorrower[msg.sender].length,
        borrower: msg.sender,
        amount: amount,
        collateral: collateralAmount,
        interest: interest,
        startTimestamp: block.timestamp,
        endTimestamp: block.timestamp + 30 days,
        active: true
    });

    loansByBorrower[msg.sender].push(loan);
    loansById[loan.id] = loan;

    borrowingCollateral[collateralToken] += collateralAmount;
    borrowingDebt[tokenAddress] += amount;
    borrowingUtilization = (borrowingDebt[tokenAddress] * BASE) / token.balance;

    emit NewLoan(msg.sender, amount, collateralAmount);
}

function repayLoan(uint256 loanId, address _token) public {
    Loan storage loan = loansById[loanId];
    require(loan.active, "Loan is not active");

    Token storage token = tokens[_token];
    IERC20(token.tokenAddress).transferFrom(msg.sender, address(this), loan.amount);

    uint256 cashback = (loan.interest * CASHBACK_PERCENTAGE) / 100;
    uint256 netRepayment = loan.amount + loan.interest - cashback;

    IERC20(token.tokenAddress).transfer(owner, cashback);
    token.balance += netRepayment;
    totalLoans += loan.amount;

    borrowingCollateral[_token] -= loan.collateral;
    borrowingDebt[_token] -= loan.amount;
    borrowingUtilization = (borrowingDebt[msg.sender] * BASE) / token.balance;

    loan.active = false;

    emit LoanRepayed(loanId, loan.borrower, loan.amount, loan.interest);

}

function calculateDividends() public view returns (uint256) {
    uint256 totalDeposits = tokens[0xdAC17F958D2ee523a2206206994597C13D831ec7].balance
    + tokens[0x6B175474E89094C44Da98b954EedeAC495271d0F].balance
    + tokens[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48].balance;
    uint256 monthlyDividend = (totalDeposits * MONTHLY_DIVIDEND_PERCENTAGE) / (BASE * 100);
    return monthlyDividend;
}

// function distributeDividends(address tokenAddress) public {
//     require(msg.sender == owner, "Only the contract owner can distribute dividends");
//     uint256 totalDeposits = tokens[0xdAC17F958D2ee523a2206206994597C13D831ec7].balance +
//     tokens[0x6B175474E89094C44Da98b954EedeAC495271d0F].balance +
//     tokens[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48].balance;
//     uint256 monthlyDividend = (totalDeposits * MONTHLY_DIVIDEND_PERCENTAGE) / (BASE * 100);
//     uint256 availableDividend = monthlyDividend - dividendPool;
//     require(availableDividend > 0, "There are no dividends to distribute");
//     uint256 cashback = (availableDividend * CASHBACK_PERCENTAGE) / 100;
//     dividendPool += availableDividend - cashback;
//     uint256 totalShares = totalFunds - totalLoans;
//     for (uint256 i = 0; i < loansById; i++) {
//     Loan storage loan = loansById[i];
//     uint256 loanBalance = calculateLoanBalance(loan, interest);
//     uint256 interest = (loanBalance * DIVIDEND_PERCENTAGE) / (BASE * 100);
//     dividends[loan.borrower] += (loanBalance * BASE * loan.endTimestamp / 2629743 / totalShares) * monthlyDividend / BASE + interest;
//     }
//     for (uint256 i = 0; i < dividendWithdrawals.length; i++) {
//     address to = dividendWithdrawals[i];
//     uint256 amount = dividends[to];
//     dividends[to] = 0;
//     IERC20(tokenAddress).transfer(to, amount);
//     emit DividendPaid(to, amount);
//     }
//     IERC20(tokenAddress).transfer(owner, cashback);
//     emit CashbackPaid(owner, cashback);
//     }

function calculateLoanBalance(uint256 loanAmount, uint256 interestRate, uint256 loanStartTime) public view returns (uint256) {
    // Calculate the elapsed time since the loan was taken out
    uint256 elapsedTime = block.timestamp - loanStartTime;

    // Calculate the interest accrued on the loan based on the elapsed time and interest rate
    uint256 interestAccrued = loanAmount * interestRate * elapsedTime / (365 days * 100);

    // Calculate the total loan balance (principal + interest)
    uint256 totalBalance = loanAmount + interestAccrued;

    return totalBalance;
}

}