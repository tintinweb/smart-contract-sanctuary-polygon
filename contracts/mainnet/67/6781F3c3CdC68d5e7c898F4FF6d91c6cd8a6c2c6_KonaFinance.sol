// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./AccessControl.sol";
import "./IERC20.sol";
import "./Strings.sol";
import "./KonaOracle.sol";

interface IStrategy {
    function strategyRepay(uint256 _total, uint256 _providerID, uint256 _loanId) external;
    function cancelStrategy(uint256 _providerID, uint256 _loanID) external;
}

contract KonaFinance is KonaOracle, AccessControl {
    address brzToken = 0x491a4eB4f1FC3BfF8E1d2FC856a6A46663aD556f;

    struct Provider {
        bool valid;
        string name;
        string apiURL;
        string apiSuffix;
        bool autoConfirm;
        uint256 maxLoanAmount;
        uint256[] feeAmounts;
        address[] feeWallets;
        mapping(address => bool) creators;
        mapping(uint256 => Loan) loans;
    }

    struct Numbers {
        uint256 apy; 
        uint256 totalLocked; 
        uint256 repayments; 
        uint256 maturity; 
    }

    struct Loan {
        bool valid;

        uint256 amount;
        address borrower; 
        uint256 taxIdentification;

        bool invested;
        address lender;
        uint256 lenderToClaim; 
        address payToContract;

        string lockReference;
        uint256 totalRepaid; 
        bool confirmationRequired;

        Numbers numbers;
    }

    mapping(uint256 => Provider) public providers;

    uint256 public konaFees = 5; //5%
    address public konaAddress;
    mapping(address=>uint256) public feesToCollect;

    bool public oracleEnabled = true;

    event LoanCreated(uint256 indexed providerID, uint256 indexed loanID,  address indexed creator, uint256 amount, address borrower, uint256 apy);
    event LoanPreInvested(uint256 indexed providerID, uint256 indexed loanID, address indexed lender);
    event LoanInvested(uint256 indexed providerID, uint256 indexed loanID, address indexed lender);
    event LoanCancelled(uint256 indexed providerID, uint256 indexed loanID);
    event LoanDeleted(uint256 indexed providerID, uint256 indexed loanID, address indexed lender);
    event LoanRepaid(uint256 indexed providerID, uint256 indexed loanID, address contractAddreess, uint256 amount);
    event LoanPendingConfirm(uint256 indexed providerID, uint256 indexed loanID, address indexed lender, uint256 amount);
    event LoanWithdrawn(uint256 indexed providerID, uint256 indexed loanID, address indexed lender, uint256 amount);

    event LenderClaimed(uint256 indexed providerID, uint256 indexed loanID, address indexed lender, uint256 total);
    event FeesAdded(address indexed beneficiary, uint256 total);
    event FeesClaimed(address indexed caller, uint256 total);

    event ProviderEnabled(uint256 indexed providerID, string name, string apiURL, string apiSuffix, uint256[] feeAmounts, address[] feeWallets);
    event ProviderCreatorSet(uint256 indexed providerID, address indexed creator, bool enabled);
    event ProviderDisabled(uint256 indexed providerID);
    event ProviderUpdated(uint256 indexed providerID, string apiURL, string apiSuffix, bool autoConfirm,  uint256 maxLoanAmount);
    event ProviderFeesReplaced(uint256 indexed providerID, uint256[] feeAmounts, address[] feeWallets);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        konaAddress = msg.sender;
    }

    function createLoan(uint256 _providerID, uint256 _loanID, uint256 _amount, address _borrower, uint256 _taxIdentification, uint256 _maturity, uint256 _repayments, uint256 _totalLocked, uint256 _apy) public {
        require(providers[_providerID].valid, "Invalid provider");
        require(providers[_providerID].creators[msg.sender], "Forbidden access");
        require(!providers[_providerID].loans[_loanID].valid, "Loan ID already created");
        require(_amount > 0, "Invalid amount");
        require(_borrower != address(0), "Invalid borrower address");
        require(_taxIdentification > 0, "Invalid Tax Identification");
        require(providers[_providerID].maxLoanAmount == 0 || _amount <= providers[_providerID].maxLoanAmount, "Max amount reached");

        Loan storage loan = providers[_providerID].loans[_loanID];
        
        loan.valid = true;
        loan.amount = _amount;
        loan.borrower = _borrower;
        loan.taxIdentification = _taxIdentification;
        loan.numbers.maturity = _maturity;
        loan.numbers.repayments = _repayments;
        loan.numbers.totalLocked = _totalLocked;
        loan.numbers.apy = _apy;

        emit LoanCreated(_providerID, _loanID, msg.sender, _amount, _borrower, _apy);
    }

    function invest(uint256 _providerID, uint256 _loanID, address _payToContract) external {
        Loan storage loan = providers[_providerID].loans[_loanID];

        require(IERC20(brzToken).balanceOf(msg.sender) >= loan.amount, "You don't have enough founds");
        require(IERC20(brzToken).allowance(msg.sender, address(this)) >= loan.amount,"You must approve the contract first");

        require (loan.lender == address(0), "Loan already invested"); 

        loan.lender = msg.sender;
        loan.payToContract = _payToContract;

        if (oracleEnabled) {
            string memory url = string(abi.encodePacked(string.concat(providers[_providerID].apiURL, Strings.toString(_loanID), providers[_providerID].apiSuffix)));
            callOracle(_providerID, _loanID, url, this.fulfill.selector);
        }

        emit LoanPreInvested(_providerID, _loanID, msg.sender);
    }

    function setLoanAsLockDone(uint256 _providerID, uint256 _loanID, string memory _lockReference) external {
        require(providers[_providerID].valid, "Invalid provider");
        require(providers[_providerID].creators[msg.sender], "Forbidden access");

        Loan storage loan = providers[_providerID].loans[_loanID];

        require(loan.valid, "Invalid loan");
        require(loan.invested, "Not invested");

        loan.lockReference = _lockReference;

        if (providers[_providerID].autoConfirm) {
            require(IERC20(brzToken).transfer(loan.borrower, loan.amount));
            emit LoanWithdrawn(_providerID, _loanID, loan.borrower, loan.amount);    
        } else {
            loan.confirmationRequired = true;
            emit LoanPendingConfirm(_providerID, _loanID, loan.borrower, loan.amount);    
        }
    }

    function confirmLoanWithdrawal(uint256 _providerID, uint256 _loanID) public onlyRole(DEFAULT_ADMIN_ROLE) {
        Loan storage loan = providers[_providerID].loans[_loanID];

        require(loan.confirmationRequired, "Loan already confirmed");

        loan.confirmationRequired = false;

        require(IERC20(brzToken).transfer(loan.borrower, loan.amount));

        emit LoanWithdrawn(_providerID, _loanID, loan.borrower, loan.amount);    
    }

    function cancelLoan(uint256 _providerID, uint256 _loanID) public {
        require(providers[_providerID].valid, "Invalid provider");
        require(providers[_providerID].creators[msg.sender], "Forbidden access");

        Loan memory loan = providers[_providerID].loans[_loanID];

        require(loan.valid, "Invalid loan");
        require(!loan.invested, "Loan already invested");

        delete providers[_providerID].loans[_loanID];

        emit LoanCancelled(_providerID, _loanID);
    }

    function deleteLoan(uint256 _providerID, uint256 _loanID) external {
        require(providers[_providerID].valid, "Invalid provider");
        require(providers[_providerID].creators[msg.sender], "Forbidden access");

        Loan memory loan = providers[_providerID].loans[_loanID];

        require(loan.valid, "Invalid loan");

        //Reimburse lender
        if (loan.invested) {
            if (loan.payToContract == address(0)) {
                IERC20(brzToken).transfer(loan.lender, loan.amount);
            } else {
                IStrategy(loan.payToContract).cancelStrategy(_providerID, _loanID);
            }
        }

        address lender = providers[_providerID].loans[_loanID].lender;

        delete providers[_providerID].loans[_loanID];

        emit LoanDeleted(_providerID, _loanID, lender);
    }

    function repay(uint256 _amount, uint256 _providerID, uint256 _loanID) external {
        require(IERC20(brzToken).transferFrom(msg.sender, address(this), _amount), "Error during ERC20 transferFrom");

        Loan memory loan = providers[_providerID].loans[_loanID];

        uint256 konaTotalFees = _amount * konaFees / 10000;
        feesToCollect[konaAddress] += konaTotalFees;
        emit FeesAdded(konaAddress, konaTotalFees);

        uint256 lenderTotal = _amount - konaTotalFees;

        for (uint i = 0; i < providers[_providerID].feeAmounts.length; i++) {
            uint256 total = _amount * providers[_providerID].feeAmounts[i] / 10000;
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

        emit LoanRepaid(_providerID, _loanID, loan.payToContract, _amount);
    }

    function fulfill(bytes32 _requestId, uint256 _oracleValue) public recordChainlinkFulfillment(_requestId) {
        uint256 providerID = requests[_requestId].providerID;
        uint256 loanID = requests[_requestId].loanID;
        loanChecked(providerID, loanID, _oracleValue);

        emit ResultContractData(_requestId, _oracleValue, providerID, loanID);
    }

    function loanChecked(uint256 _providerID, uint256 _loanID, uint256 _result) internal {
        if (_result == 1) {
            // There was en error, retry manually
            emit ErrorAPICall(_providerID, _loanID);
        }
        else if(_result == 3) {
            // Loan is not valid anymore
            delete providers[_providerID].loans[_loanID];

            emit LoanDeleted(_providerID, _loanID, address(0));
        } else {
            Loan memory loan = providers[_providerID].loans[_loanID];

            // In case of error during funds transfer, another investor is allowed to invest
            if (IERC20(brzToken).balanceOf(loan.lender) < loan.amount || IERC20(brzToken).allowance(loan.lender, address(this)) < loan.amount){
                providers[_providerID].loans[_loanID].lender = address(0);
            } else {
                // The investment is accepted
                IERC20(brzToken).transferFrom(loan.lender, address(this), loan.amount);
                providers[_providerID].loans[_loanID].invested = true;

                emit LoanInvested(_providerID, _loanID, loan.lender);
            }
        }
    }

    function lenderClaim(uint256 _providerID, uint256 _loanID) external {
        require(providers[_providerID].valid, "Invalid provider");
        require(providers[_providerID].loans[_loanID].valid, "Invalid loan");

        Loan storage loan = providers[_providerID].loans[_loanID];

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

    function enableProvider(uint256 _providerID, string calldata _name, string calldata _apiURL, string calldata _apiSuffix, uint256[] calldata _feeAmounts, address[] calldata _feeWallets) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!providers[_providerID].valid, "Already enabled");
        require(_feeAmounts.length == _feeWallets.length, "Fee lengths do not match");

        Provider storage provider = providers[_providerID];
        provider.valid = true;
        provider.name = _name;
        provider.apiURL = _apiURL;
        provider.apiSuffix = _apiSuffix;

        for (uint i = 0; i < _feeAmounts.length; i++) {
            provider.feeAmounts.push(_feeAmounts[i]);
            provider.feeWallets.push(_feeWallets[i]);
        }

        emit ProviderEnabled(_providerID, _name, _apiURL, _apiSuffix, _feeAmounts, _feeWallets);
    }

    function updateProvider(uint256 _providerID, string memory _apiURL, string memory _apiSuffix, bool _autoConfirm, uint256 _maxLoanAmount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(providers[_providerID].valid, "Invalid provider");

        Provider storage provider = providers[_providerID];
        provider.apiURL = _apiURL;
        provider.apiSuffix = _apiSuffix;
        provider.autoConfirm = _autoConfirm;
        provider.maxLoanAmount = _maxLoanAmount;

        emit ProviderUpdated(_providerID, _apiURL, _apiSuffix, _autoConfirm, _maxLoanAmount);
    }

    function replaceProviderFees(uint256 _providerID, uint256[] calldata _feeAmounts, address[] calldata _feeWallets) external onlyRole(DEFAULT_ADMIN_ROLE) {
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

    function setProviderCreator(uint256 _providerID, address _creator, bool _enabled) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(providers[_providerID].valid, "Invalid provider");

        providers[_providerID].creators[_creator] = _enabled;

        emit ProviderCreatorSet(_providerID, _creator, _enabled);
    }

    function disableProvider(uint256 _providerID) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(providers[_providerID].valid, "Invalid provider");

        delete providers[_providerID];

        emit ProviderDisabled(_providerID);
    }

    function updateLoanState(uint256 _providerID, uint256 _loanID, address _lender, address _payToContract, bool _invested) external onlyRole(DEFAULT_ADMIN_ROLE) {
        providers[_providerID].loans[_loanID].lender = _lender;        
        providers[_providerID].loans[_loanID].payToContract = _payToContract;
        providers[_providerID].loans[_loanID].invested = _invested;
    }

    function updateLoanNumbers(uint256 _providerID, uint256 _loanID, uint256 _maturity, uint256 _repayments, uint256 _totalLocked, uint256 _apy) external onlyRole(DEFAULT_ADMIN_ROLE) {
        providers[_providerID].loans[_loanID].numbers.maturity = _maturity;        
        providers[_providerID].loans[_loanID].numbers.totalLocked = _totalLocked;
        providers[_providerID].loans[_loanID].numbers.repayments = _repayments;
        providers[_providerID].loans[_loanID].numbers.apy = _apy;
    }

    function setKonaFees(uint256 _konaFees, address _konaAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        konaFees = _konaFees;
        konaAddress = _konaAddress;
    }

    function setOracleEnabled(bool _oracleEnabled) external onlyRole(DEFAULT_ADMIN_ROLE) {
        oracleEnabled = _oracleEnabled;
    }

    function recoverTokens(uint256 _amount, address _asset) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(IERC20(_asset).transfer(msg.sender, _amount), 'Transfer failed');
    }

    function recoverETH(uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(msg.sender).transfer(_amount);
    }

    function getProviderFees(uint256 _providerID) external view returns(uint256[] memory feeAmounts, address[] memory feeWallets) {
        if (providers[_providerID].valid) {
            feeAmounts = providers[_providerID].feeAmounts;
            feeWallets = providers[_providerID].feeWallets;
        }
    }

    function getLoan(uint256 _providerID, uint256 _loanID) external view returns (uint256, address, bool, address, uint256, address, string memory, uint256, bool) {
        Loan memory loan = providers[_providerID].loans[_loanID];
        
        if (!providers[_providerID].valid || !loan.valid) {
            return (0, address(0), false, address(0), 0, address(0), '', 0, false);
        }

        return (loan.amount, loan.borrower, loan.invested, loan.lender, loan.lenderToClaim, loan.payToContract, loan.lockReference, loan.totalRepaid, loan.confirmationRequired);
    }

    function getLoanBasic(uint256 _providerID, uint256 _loanID) external view returns (bool, uint256, bool, uint256) {
        Loan memory loan = providers[_providerID].loans[_loanID];

        if (!providers[_providerID].valid || !loan.valid) {
            return (false, 0, false, 0);
        }

        return (true, loan.amount, loan.invested, loan.numbers.repayments);
    }
}