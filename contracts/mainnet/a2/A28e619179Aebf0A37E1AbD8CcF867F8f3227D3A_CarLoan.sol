pragma solidity ^0.8.0;

contract CarLoan {
    struct Loan {
        uint256 amount;
        uint256 interestRate;
        uint256 collateral;
        bool approved;
        bool repaid;
    }

    mapping(address => Loan) public loans;
    uint256 public maxLoanAmount;
    uint256 public baseInterestRate;
    address public owner;
    bool public stopped = false;

    modifier onlyOwner {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }

    modifier stopInEmergency { 
        require(!stopped, "The contract is currently stopped."); 
        _; 
    }

    constructor(uint256 _maxLoanAmount, uint256 _baseInterestRate) {
        maxLoanAmount = _maxLoanAmount;
        baseInterestRate = _baseInterestRate;
        owner = msg.sender; // The contract deployer becomes the owner.
    }

    function toggleContractActive() public onlyOwner { // Circuit breaker pattern for emergency stop
        stopped = !stopped;
    }

    function requestLoan(uint256 _amount, uint256 _collateral) public stopInEmergency {
        require(loans[msg.sender].amount == 0, "Existing loan must be repaid first.");
        loans[msg.sender] = Loan(_amount, baseInterestRate, _collateral, false, false);
    }

    function approveLoan(address _borrower) public onlyOwner {
        Loan storage loan = loans[_borrower];
        require(loan.amount > 0, "Loan request not found.");
        require(loan.collateral >= loan.amount * (100 + loan.interestRate) / 100, "Insufficient collateral.");
        loan.approved = true;
    }

    function repayLoan() public payable stopInEmergency {
        Loan storage loan = loans[msg.sender];
        require(loan.approved, "Loan not approved.");
        uint256 repaymentAmount = loan.amount * (100 + loan.interestRate) / 100;
        require(msg.value == repaymentAmount, "Incorrect repayment amount.");
        loan.repaid = true;
    }
}