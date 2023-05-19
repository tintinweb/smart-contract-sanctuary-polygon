// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IERC20.sol";
import './KonaStorage.sol';
import './IKonaFinance.sol';
import './IStrategy.sol';


contract KonaFinance is KonaStorage, IKonaFinance {
    address brzToken = 0x491a4eB4f1FC3BfF8E1d2FC856a6A46663aD556f;

    constructor() {
        konaAddress = msg.sender;
    }

    function createLoan(uint256 _providerID, uint256 _loanID, uint256 _amount, address _borrower, string memory _borrowerInfo, uint256 _maturity, uint256 _repayments, uint256 _interestRate, uint256 _amountPlusInterest, uint256 _excessCollateral) external {
        require(providers[_providerID].valid, "Invalid provider");
        require(providers[_providerID].creators[msg.sender], "Forbidden access");
        require(!providers[_providerID].loans[_loanID].valid, "Loan ID already created");
        require(_amount > 0 && _interestRate > 0 && _amountPlusInterest >= _amount, "Invalid conditions");
        require((rampAddress != address(0) && _borrower == rampAddress) || (rampAddress == address(0) && _borrower != address(0)), "Invalid borrower address");
        require(providers[_providerID].maxLoanAmount == 0 || _amount <= providers[_providerID].maxLoanAmount, "Max amount reached");

        Loan storage loan = providers[_providerID].loans[_loanID];
        
        loan.valid = true;

        //Approve automatically if using Kona's Oracle
        if (providers[_providerID].autoApprove) {
            loan.status = LoanStatus.Approved;
            emit LoanApproved(_providerID, _loanID, '-');
        } else {
            loan.status = LoanStatus.Created;
        }

        loan.amount = _amount;
        loan.borrower = _borrower;
        loan.borrowerInfo = _borrowerInfo;
        loan.conditions.maturity = _maturity;
        loan.conditions.repayments = _repayments;
        loan.conditions.interestRate = _interestRate;
        loan.conditions.amountPlusInterest = _amountPlusInterest;
        loan.conditions.excessCollateral = _excessCollateral;

        emit LoanCreated(_providerID, _loanID, msg.sender, _amount, _borrower, uint8(loan.status));
    }

    function approveLoan(uint256 _providerID, uint256 _loanID, string memory _lockReference) external onlyRole(LOAN_CONFIRM_ROLE) {
        Loan storage loan = providers[_providerID].loans[_loanID];

        require(loan.status == LoanStatus.Created, "Loan already approved");

        loan.status = LoanStatus.Approved;
        loan.lockReference = _lockReference;

        emit LoanApproved(_providerID, _loanID, _lockReference);
    }

    function invest(uint256 _providerID, uint256 _loanID, address _payToContract) external {
        require(providers[_providerID].valid, "Invalid provider");

        Loan storage loan = providers[_providerID].loans[_loanID];

        require(loan.valid, "Invalid loan");
        require(loan.status == LoanStatus.Approved, "Loan is not approved yet");

        loan.lender = msg.sender;
        loan.payToContract = _payToContract;
        loan.status = LoanStatus.Invested;

        require(IERC20(brzToken).transferFrom(msg.sender, address(this), loan.amount), "Transfer failed");

        emit LoanInvested(_providerID, _loanID, msg.sender);
    }

    function confirmLoanWithdrawal(uint256 _providerID, uint256 _loanID, string memory _lockReference) external onlyRole(LOAN_CONFIRM_ROLE) {
        require(providers[_providerID].valid, "Invalid provider");

        Loan storage loan = providers[_providerID].loans[_loanID];

        require(loan.valid, "Invalid loan");
        require(loan.status == LoanStatus.Invested, "Loan is not invested yet");

        loan.status = LoanStatus.Withdrawn;
        loan.lockReference = _lockReference;

        require(IERC20(brzToken).transfer(loan.borrower, loan.amount));

        emit LoanWithdrawn(_providerID, _loanID, loan.lender, loan.amount);
    }

    function cancelLoan(uint256 _providerID, uint256 _loanID) public {
        require(providers[_providerID].valid, "Invalid provider");
        require(providers[_providerID].creators[msg.sender] || hasRole(LOAN_MANAGER_ROLE, msg.sender), "Forbidden access");

        Loan memory loan = providers[_providerID].loans[_loanID];

        require(loan.valid, "Invalid loan");

        uint256 totalReimbursed = 0;

        if (loan.status == LoanStatus.Invested) {
            totalReimbursed = reimburseLender(_providerID, _loanID, loan.payToContract, loan.lender, loan.amount);
        } else {
            require(loan.status == LoanStatus.Approved, "Invalid status");
        }

        loan.status = LoanStatus.Cancelled;

        emit LoanCancelled(_providerID, _loanID, loan.lender, totalReimbursed);
    }

    function deleteLoan(uint256 _providerID, uint256 _loanID) external onlyRole(LOAN_MANAGER_ROLE) {
        require(providers[_providerID].valid, "Invalid provider");

        Loan memory loan = providers[_providerID].loans[_loanID];

        require(loan.valid, "Invalid loan");

        uint256 totalReimbursed = 0;

        if (loan.status == LoanStatus.Invested) {
            totalReimbursed = reimburseLender(_providerID, _loanID, loan.payToContract, loan.lender, loan.amount);
        }

        delete providers[_providerID].loans[_loanID];

        emit LoanDeleted(_providerID, _loanID, loan.lender, totalReimbursed);
    }

    function reimburseLender(uint256 _providerID, uint256 _loanID, address _payToContract, address _lender, uint256 _amount) internal returns(uint256) {
        if (_payToContract == address(0)) {
            IERC20(brzToken).transfer(_lender, _amount);
        } else {
            IStrategy(_payToContract).cancelStrategy(_providerID, _loanID);
        }

        return _amount;
    }

    //Extra collateral is paid back off-chain before calling repay
    function repay(uint256 _amount, uint256 _providerID, uint256 _loanID) external {
        require(providers[_providerID].valid, "Invalid provider");

        require(IERC20(brzToken).transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        Loan memory loan = providers[_providerID].loans[_loanID];

        require(loan.valid, "Invalid loan");
        require(loan.status == LoanStatus.Withdrawn, "Invalid status");

        uint256 lenderTotal = _amount;

        uint256 konaTotalFees = 0;

        if (konaFees > 0) {
            konaTotalFees += lenderTotal * konaFees / 1e4;
            feesToCollect[konaAddress] += konaTotalFees;
            lenderTotal -= konaTotalFees;
            emit FeesAdded(konaAddress, konaTotalFees);
        }

        for (uint i = 0; i < providers[_providerID].feeAmounts.length; i++) {
            uint256 total = _amount * providers[_providerID].feeAmounts[i] / 1e4;
            address beneficiary = providers[_providerID].feeWallets[i];
            feesToCollect[beneficiary] += total;
            lenderTotal -= total;
            emit FeesAdded(beneficiary, total);
        }

        if (loan.payToContract == address(0)) {
            providers[_providerID].loans[_loanID].lenderToClaim += lenderTotal; 
        } else {
            IERC20(brzToken).approve(loan.payToContract, lenderTotal);
            IStrategy(loan.payToContract).strategyRepay(lenderTotal, _providerID, _loanID);
        }

        providers[_providerID].loans[_loanID].totalRepaid += lenderTotal;

        emit LoanRepaid(_providerID, _loanID, loan.payToContract, _amount, konaTotalFees, lenderTotal);
    }

    function lenderClaim(uint256 _providerID, uint256 _loanID) external {
        require(providers[_providerID].valid, "Invalid provider");

        Loan storage loan = providers[_providerID].loans[_loanID];

        require(loan.valid, "Invalid loan");
        require(loan.lender == msg.sender, "Invalid caller");
        require(loan.payToContract == address(0), "Payments are automatic"); 
        require(loan.lenderToClaim >= 0, "Nothing to claim");

        uint256 total = loan.lenderToClaim;

        loan.lenderToClaim = 0;

        IERC20(brzToken).transfer(msg.sender, total);

        emit LenderClaimed(_providerID, _loanID, msg.sender, total);
    }

    function claimFees() external {
        uint256 total = feesToCollect[msg.sender];

        require(total > 0, "Nothing to claim");

        feesToCollect[msg.sender] = 0;
        IERC20(brzToken).transfer(msg.sender, total);

        emit FeesClaimed(msg.sender, total);
    }

    function enableProvider(uint256 _providerID, string calldata _name, bool _autoApprove, uint256[] calldata _feeAmounts, address[] calldata _feeWallets) external onlyRole(PROVIDER_MANAGER_ROLE) {
        require(!providers[_providerID].valid, "Already enabled");
        require(_feeAmounts.length == _feeWallets.length, "Fee lengths do not match");

        Provider storage provider = providers[_providerID];
        provider.valid = true;
        provider.name = _name;
        provider.autoApprove = _autoApprove;

        for (uint i = 0; i < _feeAmounts.length; i++) {
            provider.feeAmounts.push(_feeAmounts[i]);
            provider.feeWallets.push(_feeWallets[i]);
        }

        providers[_providerID].creators[msg.sender] = true;

        emit ProviderEnabled(_providerID, _name, _autoApprove, _feeAmounts, _feeWallets);
    }

    function updateProvider(uint256 _providerID, bool _autoApprove, uint256 _maxLoanAmount) external onlyRole(PROVIDER_MANAGER_ROLE) {
        require(providers[_providerID].valid, "Invalid provider");

        Provider storage provider = providers[_providerID];
        provider.autoApprove = _autoApprove;
        provider.maxLoanAmount = _maxLoanAmount;

        emit ProviderUpdated(_providerID, _autoApprove, _maxLoanAmount);
    }

    function replaceProviderFees(uint256 _providerID, uint256[] calldata _feeAmounts, address[] calldata _feeWallets) external onlyRole(PROVIDER_MANAGER_ROLE) {
        require(providers[_providerID].valid, "Invalid provider");
        require(_feeAmounts.length == _feeWallets.length, "Fee lengths do not match");

        delete providers[_providerID].feeAmounts;
        delete providers[_providerID].feeWallets;

        for (uint i = 0; i < _feeAmounts.length; i++) {
            providers[_providerID].feeAmounts.push(_feeAmounts[i]);
            providers[_providerID].feeWallets.push(_feeWallets[i]);
        }

        emit ProviderFeesReplaced(_providerID, _feeAmounts, _feeWallets);
    }

    function setProviderCreator(uint256 _providerID, address _creator, bool _enabled) external onlyRole(PROVIDER_MANAGER_ROLE) {
        require(providers[_providerID].valid, "Invalid provider");

        providers[_providerID].creators[_creator] = _enabled;

        emit ProviderCreatorSet(_providerID, _creator, _enabled);
    }

    function disableProvider(uint256 _providerID) external onlyRole(PROVIDER_MANAGER_ROLE) {
        require(providers[_providerID].valid, "Invalid provider");

        delete providers[_providerID];

        emit ProviderDisabled(_providerID);
    }

    function updateLoanState(uint256 _providerID, uint256 _loanID, address _lender, address _payToContract, LoanStatus _status) external onlyRole(LOAN_MANAGER_ROLE) {
        providers[_providerID].loans[_loanID].lender = _lender;        
        providers[_providerID].loans[_loanID].payToContract = _payToContract;
        providers[_providerID].loans[_loanID].status = _status;

        emit LoanUpdated(_providerID, _loanID);
    }

    function updateLoanInfo(uint256 _providerID, uint256 _loanID, uint256 _amount, address _borrower, string memory _borrowerInfo, uint256 _maturity, uint256 _repayments, uint256 _interestRate, uint256 _amountPlusInterest, uint256 _excessCollateral) external {
        require(providers[_providerID].valid, "Invalid provider");

        Loan storage loan = providers[_providerID].loans[_loanID];

        require(loan.valid, "Invalid loan");

        if (!hasRole(LOAN_MANAGER_ROLE, msg.sender)) {
            require(providers[_providerID].creators[msg.sender], "Forbidden access");
            require(loan.status == LoanStatus.Created, "Invalid status");
        }

        require(_amount > 0 && _interestRate > 0 && _amountPlusInterest >= _amount, "Invalid conditions");
        require((rampAddress != address(0) && _borrower == rampAddress) || (rampAddress == address(0) && _borrower != address(0)), "Invalid borrower address");
        require(providers[_providerID].maxLoanAmount == 0 || _amount <= providers[_providerID].maxLoanAmount, "Max amount reached");

        loan.amount = _amount;        
        loan.borrower = _borrower;        
        loan.borrowerInfo = _borrowerInfo;        
        loan.conditions.maturity = _maturity;
        loan.conditions.repayments = _repayments;
        loan.conditions.interestRate = _interestRate;
        loan.conditions.amountPlusInterest = _amountPlusInterest;
        loan.conditions.excessCollateral = _excessCollateral;

        emit LoanUpdated(_providerID, _loanID);
    }

    function setKonaFees(uint256 _konaFees, address _konaAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        konaFees = _konaFees;
        konaAddress = _konaAddress;
    }

    function setRampAddress(address _rampAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        rampAddress = _rampAddress;
    }

    function recoverTokens(uint256 _amount, address _asset) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(IERC20(_asset).transfer(msg.sender, _amount), 'Transfer failed');
    }

    function recoverETH(uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(msg.sender).transfer(_amount);
    }
}