// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "./context/SaplingManagerContext.sol";
import "./interfaces/ILoanDesk.sol";
import "./interfaces/IPoolContext.sol";
import "./interfaces/ILendingPool.sol";

import "./lib/SaplingMath.sol";
import "./lib/Limits.sol";

/**
 * @title Loan Desk
 * @notice Provides loan application and offer management.
 */
contract LoanDesk is ILoanDesk, SaplingManagerContext, ReentrancyGuardUpgradeable {

    /// Address of the lending pool contract
    address public pool;

    /// Default loan parameter values
    LoanTemplate public loanTemplate;


    // Loan applications state 

    /// Loan application id generator counter
    uint256 private nextApplicationId;

    /// Total liquidity tokens allocated for loan offers and pending acceptance by the borrowers
    uint256 public offeredFunds;

    /// Loan applications by applicationId
    mapping(uint256 => LoanApplication) public loanApplications;

    /// Loan offers by applicationId
    mapping(uint256 => LoanOffer) public loanOffers;

    /// Recent application id by address
    mapping(address => uint256) public recentApplicationIdOf;


    // Loans state

    /// Loan id generator counter
    uint256 private nextLoanId;

    uint256 public outstandingLoansCount;

    /// Loans by loan ID
    mapping(uint256 => Loan) public loans;

    /// LoanDetails by loan ID
    mapping(uint256 => LoanDetail) public loanDetails;


    /// A modifier to limit access only to when the application exists and has the specified status
    modifier applicationInStatus(uint256 applicationId, LoanApplicationStatus status) {
        require(applicationId != 0, "LoanDesk: invalid id");
        require(loanApplications[applicationId].id == applicationId, "LoanDesk: not found");
        require(loanApplications[applicationId].status == status, "LoanDesk: invalid status");
        _;
    }

    modifier loanInStatus(uint256 loanId, LoanStatus status) {
        require(loanId != 0, "LoanDesk: invalid id");
        require(loans[loanId].id == loanId, "LoanDesk: not found");
        require(loans[loanId].status == status, "LoanDesk: invalid status");
        _;
    }

    /**
     * @dev Disable initializers
     */
    function disableIntitializers() external onlyRole(SaplingRoles.GOVERNANCE_ROLE) {
        _disableInitializers();
    }

    /**
     * @notice Initializer a new LoanDesk.
     * @dev Addresses must not be 0.
     * @param _pool Lending pool address
     * @param _accessControl Access control contract
     * @param _decimals Lending pool liquidity token decimals
     */
    function initialize(
        address _pool,
        address _accessControl,
        bytes32 _managerRole,
        uint8 _decimals
    )
        public
        initializer
    {
        __SaplingManagerContext_init(_accessControl, _managerRole);

        /*
            Additional check for single init:
                do not init again if a non-zero value is present in the values yet to be initialized.
        */
        assert(pool == address(0) && nextApplicationId == 0);

        require(_pool != address(0), "LoanDesk: invalid pool address");

        loanTemplate = LoanTemplate({
            minAmount: 100 * 10 ** uint256(_decimals),
            minDuration: Limits.SAFE_MIN_DURATION,
            maxDuration: Limits.SAFE_MAX_DURATION,
            gracePeriod: 60 days,
            apr: uint16(30 * 10 ** SaplingMath.PERCENT_DECIMALS) // 30%
        });

        pool = _pool;
        offeredFunds = 0;
        outstandingLoansCount = 0;
        nextApplicationId = 1;
        nextLoanId = 1;
    }

    /**
     * @notice Set a minimum loan amount.
     * @dev minAmount must be greater than or equal to safeMinAmount.
     *      Caller must be the manager.
     * @param minAmount Minimum loan amount to be enforced on new loan requests and offers
     */
    function setMinLoanAmount(uint256 minAmount) external onlyRole(poolManagerRole) {
        require(Limits.SAFE_MIN_AMOUNT <= minAmount, "LoanDesk: new min loan amount is less than the safe limit");

        uint256 prevValue = loanTemplate.minAmount;
        loanTemplate.minAmount = minAmount;

        emit MinLoanAmountSet(prevValue, loanTemplate.minAmount);
    }

    /**
     * @notice Set the minimum loan duration
     * @dev Duration must be in seconds and inclusively between SAFE_MIN_DURATION and maxDuration.
     *      Caller must be the manager.
     * @param duration Minimum loan duration to be enforced on new loan requests and offers
     */
    function setMinLoanDuration(uint256 duration) external onlyRole(poolManagerRole) {
        require(
            Limits.SAFE_MIN_DURATION <= duration && duration <= loanTemplate.maxDuration,
            "LoanDesk: new min duration is out of bounds"
        );

        uint256 prevValue = loanTemplate.minDuration;
        loanTemplate.minDuration = duration;

        emit MinLoanDurationSet(prevValue, loanTemplate.minDuration);
    }

    /**
     * @notice Set the maximum loan duration.
     * @dev Duration must be in seconds and inclusively between minDuration and SAFE_MAX_DURATION.
     *      Caller must be the manager.
     * @param duration Maximum loan duration to be enforced on new loan requests and offers
     */
    function setMaxLoanDuration(uint256 duration) external onlyRole(poolManagerRole) {
        require(
            loanTemplate.minDuration <= duration && duration <= Limits.SAFE_MAX_DURATION,
            "LoanDesk: new max duration is out of bounds"
        );

        uint256 prevValue = loanTemplate.maxDuration;
        loanTemplate.maxDuration = duration;

        emit MaxLoanDurationSet(prevValue, loanTemplate.maxDuration);
    }

    /**
     * @notice Set the template loan payment grace period.
     * @dev Grace period must be in seconds and inclusively between MIN_LOAN_GRACE_PERIOD and MAX_LOAN_GRACE_PERIOD.
     *      Caller must be the manager.
     * @param gracePeriod Loan payment grace period for new loan offers
     */
    function setTemplateLoanGracePeriod(uint256 gracePeriod) external onlyRole(poolManagerRole) {
        require(
            Limits.MIN_LOAN_GRACE_PERIOD <= gracePeriod && gracePeriod <= Limits.MAX_LOAN_GRACE_PERIOD,
            "LoanDesk: new grace period is out of bounds."
        );

        uint256 prevValue = loanTemplate.gracePeriod;
        loanTemplate.gracePeriod = gracePeriod;

        emit TemplateLoanGracePeriodSet(prevValue, loanTemplate.gracePeriod);
    }

    /**
     * @notice Set a template loan APR
     * @dev APR must be inclusively between SAFE_MIN_APR and 100%.
     *      Caller must be the manager.
     * @param apr Loan APR to be enforced on the new loan offers.
     */
    function setTemplateLoanAPR(uint16 apr) external onlyRole(poolManagerRole) {
        require(Limits.SAFE_MIN_APR <= apr && apr <= SaplingMath.HUNDRED_PERCENT, "LoanDesk: APR is out of bounds");

        uint256 prevValue = loanTemplate.apr;
        loanTemplate.apr = apr;

        emit TemplateLoanAPRSet(prevValue, loanTemplate.apr);
    }

    /**
     * @notice Request a new loan.
     * @dev Requested amount must be greater or equal to minLoanAmount().
     *      Loan duration must be between minDuration() and maxDuration().
     *      Multiple pending applications from the same address are not allowed -
     *      most recent loan/application of the caller must not have APPLIED status.
     * @param _amount Liquidity token amount to be borrowed
     * @param _duration Loan duration in seconds
     * @param _profileId Borrower metadata profile id obtained from the borrower service
     * @param _profileDigest Borrower metadata digest obtained from the borrower service
     */
    function requestLoan(
        uint256 _amount,
        uint256 _duration,
        string memory _profileId,
        string memory _profileDigest
    )
        external
        onlyUser
        whenNotPaused
        whenNotClosed
    {
        require(!hasOpenApplication(msg.sender), "LoanDesk: another loan application is pending");
        require(_amount >= loanTemplate.minAmount, "LoanDesk: loan amount is less than the minimum allowed");
        require(loanTemplate.minDuration <= _duration, "LoanDesk: loan duration is less than minimum allowed");
        require(loanTemplate.maxDuration >= _duration, "LoanDesk: loan duration is greater than maximum allowed");

        uint256 appId = nextApplicationId;
        nextApplicationId++;

        loanApplications[appId] = LoanApplication({
            id: appId,
            borrower: msg.sender,
            amount: _amount,
            duration: _duration,
            requestedTime: block.timestamp,
            status: LoanApplicationStatus.APPLIED,
            profileId: _profileId,
            profileDigest: _profileDigest
        });

        recentApplicationIdOf[msg.sender] = appId;

        emit LoanRequested(appId, msg.sender, _amount);
    }

    /**
     * @notice Deny a loan.
     * @dev Loan must be in APPLIED status.
     *      Caller must be the manager.
     */
    function denyLoan(
        uint256 appId
    )
        external
        onlyRole(poolManagerRole)
        applicationInStatus(appId, LoanApplicationStatus.APPLIED)
        whenNotPaused
    {
        LoanApplication storage app = loanApplications[appId];
        app.status = LoanApplicationStatus.DENIED;

        emit LoanRequestDenied(appId, app.borrower, app.amount);
    }

    /**
     * @notice Approve a loan application and offer a loan.
     * @dev Loan application must be in APPLIED status.
     *      Caller must be the manager.
     *      Loan amount must not exceed available liquidity -
     *      canOffer(offeredFunds.add(_amount)) must be true on the lending pool.
     * @param appId Loan application id
     * @param _amount Loan amount in liquidity tokens
     * @param _duration Loan term in seconds
     * @param _gracePeriod Loan payment grace period in seconds
     * @param _installmentAmount Minimum payment amount on each instalment in liquidity tokens
     * @param _installments The number of payment installments
     * @param _apr Annual percentage rate of this loan
     */
    function offerLoan(
        uint256 appId,
        uint256 _amount,
        uint256 _duration,
        uint256 _gracePeriod,
        uint256 _installmentAmount,
        uint16 _installments,
        uint16 _apr
    )
        external
        onlyRole(poolManagerRole)
        applicationInStatus(appId, LoanApplicationStatus.APPLIED)
        whenNotClosed
        whenNotPaused
    {
        //// check

        validateLoanParams(_amount, _duration, _gracePeriod, _installmentAmount, _installments, _apr);

        LoanApplication storage app = loanApplications[appId];

        require(
            ILendingPool(pool).canOffer(offeredFunds + _amount),
            "LoanDesk: lending pool cannot offer this loan at this time"
        );

        //// effect

        loanOffers[appId] = LoanOffer({
            applicationId: appId,
            borrower: app.borrower,
            amount: _amount,
            duration: _duration,
            gracePeriod: _gracePeriod,
            installmentAmount: _installmentAmount,
            installments: _installments,
            apr: _apr,
            offeredTime: block.timestamp
        });

        offeredFunds = offeredFunds + _amount;
        loanApplications[appId].status = LoanApplicationStatus.OFFER_MADE;

        //// interactions

        ILendingPool(pool).onOffer(_amount);

        emit LoanOffered(appId, app.borrower, _amount);
    }

    /**
     * @notice Update an existing loan offer.
     * @dev Loan application must be in OFFER_MADE status.
     *      Caller must be the manager.
     *      Loan amount must not exceed available liquidity -
     *      canOffer(offeredFunds.add(offeredFunds.sub(offer.amount).add(_amount))) must be true on the lending pool.
     * @param appId Loan application id
     * @param _amount Loan amount in liquidity tokens
     * @param _duration Loan term in seconds
     * @param _gracePeriod Loan payment grace period in seconds
     * @param _installmentAmount Minimum payment amount on each instalment in liquidity tokens
     * @param _installments The number of payment installments
     * @param _apr Annual percentage rate of this loan
     */
    function updateOffer(
        uint256 appId,
        uint256 _amount,
        uint256 _duration,
        uint256 _gracePeriod,
        uint256 _installmentAmount,
        uint16 _installments,
        uint16 _apr
    )
        external
        onlyRole(poolManagerRole)
        applicationInStatus(appId, LoanApplicationStatus.OFFER_MADE)
        whenNotClosed
        whenNotPaused
    {
        //// check

        validateLoanParams(_amount, _duration, _gracePeriod, _installmentAmount, _installments, _apr);

        LoanOffer storage offer = loanOffers[appId];

        uint256 prevAmount = offer.amount;

        if (prevAmount != _amount) {
            uint256 nextOfferedFunds = offeredFunds - prevAmount + _amount;
            require(ILendingPool(pool).canOffer(nextOfferedFunds),
                "LoanDesk: lending pool cannot offer this loan at this time");

            //// effect
            offeredFunds = nextOfferedFunds;
        }

        //// effect
        offer.amount = _amount;
        offer.duration = _duration;
        offer.gracePeriod = _gracePeriod;
        offer.installmentAmount = _installmentAmount;
        offer.installments = _installments;
        offer.apr = _apr;
        offer.offeredTime = block.timestamp;

        emit LoanOfferUpdated(appId, offer.borrower, prevAmount, offer.amount);

        //// interactions
        if (prevAmount != offer.amount) {
            ILendingPool(pool).onOfferUpdate(prevAmount, offer.amount);
        }
    }


    /**
     * @notice Cancel a loan.
     * @dev Loan application must be in OFFER_MADE status. Caller must be the manager.
     */
    function cancelLoan(
        uint256 appId
    )
        external
        onlyRole(poolManagerRole)
        applicationInStatus(appId, LoanApplicationStatus.OFFER_MADE)
        whenNotPaused
    {
        //// effect
        loanApplications[appId].status = LoanApplicationStatus.OFFER_CANCELLED;

        LoanOffer storage offer = loanOffers[appId];
        offeredFunds -= offer.amount;

        emit LoanOfferCancelled(appId, offer.borrower, offer.amount);

        //// interactions
        ILendingPool(pool).onOfferUpdate(offer.amount, 0);
    }

    /**
     * @notice Accept a loan offer and withdraw funds
     * @dev Caller must be the borrower of the loan in question.
     *      The loan must be in OFFER_MADE status.
     * @param appId ID of the loan application to accept the offer of
     */
    function borrow(uint256 appId) external whenNotClosed whenNotPaused {

        //// check

        LoanApplication storage app = loanApplications[appId];
        require(app.status == ILoanDesk.LoanApplicationStatus.OFFER_MADE, "LoanDesk: invalid offer status");

        LoanOffer storage offer = loanOffers[appId];
        require(offer.borrower == msg.sender, "LoanDesk: msg.sender is not the borrower on this loan");

        //// effect

        app.status = LoanApplicationStatus.OFFER_ACCEPTED;

        uint256 offerAmount = loanOffers[appId].amount;
        offeredFunds -= offerAmount;

        emit LoanOfferAccepted(appId, app.borrower, offerAmount);

        uint256 loanId = nextLoanId;
        nextLoanId++;

        loans[loanId] = Loan({
            id: loanId,
            loanDeskAddress: address(this),
            applicationId: appId,
            borrower: offer.borrower,
            amount: offer.amount,
            duration: offer.duration,
            gracePeriod: offer.gracePeriod,
            installmentAmount: offer.installmentAmount,
            installments: offer.installments,
            apr: offer.apr,
            borrowedTime: block.timestamp,
            status: LoanStatus.OUTSTANDING
        });

        loanDetails[loanId] = LoanDetail({
            loanId: loanId,
            totalAmountRepaid: 0,
            principalAmountRepaid: 0,
            interestPaid: 0,
            paymentCarry: 0,
            interestPaidTillTime: block.timestamp
        });

        outstandingLoansCount++;

        //// interactions

        // on pool
        ILendingPool(pool).onBorrow(loanId, offer.borrower, offer.amount, offer.apr);

        emit LoanBorrowed(loanId, offer.borrower, appId);
    }

    /**
     * @notice Make a payment towards a loan.
     * @dev Caller must be the borrower.
     *      Loan must be in OUTSTANDING status.
     *      Only the necessary sum is charged if amount exceeds amount due.
     *      Amount charged will not exceed the amount parameter.
     * @param loanId ID of the loan to make a payment towards.
     * @param amount Payment amount
     */
    function repay(uint256 loanId, uint256 amount) external {
        // require the payer and the borrower to be the same to avoid mispayment
        require(loans[loanId].borrower == msg.sender, "LoanDesk: payer is not the borrower");

        repayBase(loanId, amount);
    }

    /**
     * @notice Make a payment towards a loan on behalf of a borrower.
     * @dev Loan must be in OUTSTANDING status.
     *      Only the necessary sum is charged if amount exceeds amount due.
     *      Amount charged will not exceed the amount parameter.
     * @param loanId ID of the loan to make a payment towards.
     * @param amount Payment amount
     * @param borrower address of the borrower to make a payment on behalf of.
     */
    function repayOnBehalf(uint256 loanId, uint256 amount, address borrower) external {
        // require the borrower being paid on behalf off and the loan borrower to be the same to avoid mispayment
        require(loans[loanId].borrower == borrower, "LoanDesk: invalid borrower");

        repayBase(loanId, amount);
    }

    /**
     * @notice Closes a loan. Closing a loan will repay the outstanding principal using the pool manager's revenue
                            and/or staked funds. If these funds are not sufficient, the lenders will take the loss.
     * @dev Loan must be in OUTSTANDING status.
     *      Caller must be the manager.
     * @param loanId ID of the loan to close
     */
    function closeLoan(
        uint256 loanId
    )
        external
        onlyRole(poolManagerRole)
        loanInStatus(loanId, LoanStatus.OUTSTANDING)
        whenNotPaused
        nonReentrant
    {
        //// effect

        Loan storage loan = loans[loanId];
        LoanDetail storage loanDetail = loanDetails[loanId];

        uint256 amountCarryUsed = 0;

        // use loan payment carry
        if (loanDetail.paymentCarry > 0) {
            loanDetail.principalAmountRepaid += loanDetail.paymentCarry;

            amountCarryUsed = loanDetail.paymentCarry;
            loanDetail.paymentCarry = 0;
        }

        loan.status = LoanStatus.REPAID;
        outstandingLoansCount--;

        uint256 remainingDifference = loanDetail.principalAmountRepaid < loan.amount
            ? loan.amount - loanDetail.principalAmountRepaid
            : 0;

        uint256 amountRepaid = ILendingPool(pool).onCloseLoan(loan.id, loan.apr, amountCarryUsed, remainingDifference);

        // external interaction based state update (intentional)
        if (amountRepaid > 0) {
            loanDetail.totalAmountRepaid += amountRepaid - amountCarryUsed;
            loanDetail.principalAmountRepaid += amountRepaid;
        }

        remainingDifference = loanDetail.principalAmountRepaid < loan.amount
            ? loan.amount - loanDetail.principalAmountRepaid
            : 0;

        emit LoanClosed(loanId, loan.borrower, amountRepaid, remainingDifference);
    }

    /**
     * @notice Default a loan.
     * @dev Loan must be in OUTSTANDING status.
     *      Caller must be the manager.
     *      canDefault(loanId) must return 'true'.
     * @param loanId ID of the loan to default
     */
    function defaultLoan(
        uint256 loanId
    )
        external
        onlyRole(poolManagerRole)
        whenNotPaused
    {
        //// check

        require(canDefault(loanId), "LoanDesk: cannot default this loan at this time");

        //// effect

        Loan storage loan = loans[loanId];
        LoanDetail storage loanDetail = loanDetails[loanId];

        loan.status = LoanStatus.DEFAULTED;
        outstandingLoansCount--;

        uint256 paymentCarry = loanDetail.paymentCarry;

        if (loanDetail.paymentCarry > 0) {
            loanDetail.principalAmountRepaid += loanDetail.paymentCarry;
            loanDetail.paymentCarry = 0;
        }

        uint256 loss = loan.amount > loanDetail.principalAmountRepaid
            ? loan.amount - loanDetail.principalAmountRepaid
            : 0;

        (uint256 managerLoss, uint256 lenderLoss) = ILendingPool(pool).onDefault(
            loanId, 
            loan.apr, 
            paymentCarry, 
            loss
        );

        emit LoanDefaulted(loanId, loan.borrower, managerLoss, lenderLoss);
    }

    /**
     * @notice Make a payment towards a loan.
     * @dev Loan must be in OUTSTANDING status.
     *      Only the necessary sum is charged if amount exceeds amount due.
     *      Amount charged will not exceed the amount parameter.
     * @param loanId ID of the loan to make a payment towards
     * @param amount Payment amount in tokens
     */
    function repayBase(uint256 loanId, uint256 amount) internal nonReentrant whenNotPaused {

        //// check

        Loan storage loan = loans[loanId];
        require(
            loan.id == loanId && loan.status == LoanStatus.OUTSTANDING,
            "SaplingLendingPool: not found or invalid loan status"
        );

        //// effect

        (
            uint256 transferAmount,
            uint256 paymentAmount,
            uint256 interestPayable,
            uint256 payableInterestDays
        ) = payableLoanBalance(loanId, amount);

        uint256 principalPaid = paymentAmount - interestPayable;

        LoanDetail storage loanDetail = loanDetails[loanId];
        loanDetail.totalAmountRepaid += transferAmount;
        loanDetail.principalAmountRepaid += principalPaid;
        loanDetail.interestPaidTillTime += payableInterestDays * 86400;

        if (paymentAmount > transferAmount) {
            loanDetail.paymentCarry -= paymentAmount - transferAmount;
        } else if (paymentAmount < transferAmount) {
            loanDetail.paymentCarry += transferAmount - paymentAmount;
        }
        
        if (interestPayable != 0) {
            loanDetail.interestPaid += interestPayable;
        }

        if (loanDetail.principalAmountRepaid >= loan.amount) {
            loan.status = LoanStatus.REPAID;
            outstandingLoansCount--;

            emit LoanFullyRepaid(loanId, loan.borrower);
        }

        emit LoanRepaymentInitiated(loanId, loan.borrower, msg.sender, transferAmount, interestPayable);

        //// interactions

        ILendingPool(pool).onRepay(
            loanId, 
            loan.borrower, 
            msg.sender, 
            loan.apr, 
            transferAmount, 
            paymentAmount, 
            interestPayable
        );
    }

    /**
     * @notice Count of all loan requests in this pool.
     * @return LoanApplication count.
     */
    function applicationsCount() external view returns(uint256) {
        return nextApplicationId - 1;
    }

    /**
     * @notice Count of all loans in this pool.
     * @return Loan count.
     */
    function loansCount() external view returns(uint256) {
        return nextLoanId - 1;
    }

    /**
     * @notice Accessor for loan.
     * @param loanId ID of the loan
     * @return Loan struct instance for the specified loan ID.
     */
    function loanById(uint256 loanId) external view returns (Loan memory) {
        return loans[loanId];
    }

    /**
     * @notice Accessor for loan detail.
     * @param loanId ID of the loan
     * @return LoanDetail struct instance for the specified loan ID.
     */
    function loanDetailById(uint256 loanId) external view returns (LoanDetail memory) {
        return loanDetails[loanId];
    }

     /**
     * @notice Loan balance due including interest if paid in full at this time.
     * @dev Loan must be in OUTSTANDING status.
     * @param loanId ID of the loan to check the balance of
     * @return Total amount due with interest on this loan
     */
    function loanBalanceDue(uint256 loanId) external view loanInStatus(loanId, LoanStatus.OUTSTANDING) returns(uint256) {
        (uint256 principalOutstanding, uint256 interestOutstanding, ) = loanBalanceDueWithInterest(loanId);
        return principalOutstanding + interestOutstanding - loanDetails[loanId].paymentCarry;
    }

    function hasOpenApplication(address account) public view returns (bool) {
        LoanApplicationStatus recentAppStatus = loanApplications[recentApplicationIdOf[account]].status;
        return recentAppStatus == LoanApplicationStatus.APPLIED 
            || recentAppStatus == LoanApplicationStatus.OFFER_MADE;
    }

        /**
     * @notice View indicating whether or not a given loan qualifies to be defaulted
     * @param loanId ID of the loan to check
     * @return True if the given loan can be defaulted, false otherwise
     */
    function canDefault(uint256 loanId) public view loanInStatus(loanId, LoanStatus.OUTSTANDING) returns (bool) {

        Loan storage loan = loans[loanId];

        uint256 fxBandPercent = 200; //20% //TODO: use confgurable parameter on v1.1

        uint256 paymentDueTime;

        if (loan.installments > 1) {
            uint256 installmentPeriod = loan.duration / loan.installments;
            uint256 pastInstallments = (block.timestamp - loan.borrowedTime) / installmentPeriod;
            uint256 minTotalPayment = MathUpgradeable.mulDiv(
                loan.installmentAmount * pastInstallments,
                SaplingMath.HUNDRED_PERCENT - fxBandPercent,
                SaplingMath.HUNDRED_PERCENT
            );

            LoanDetail storage detail = loanDetails[loanId];
            uint256 totalRepaid = detail.principalAmountRepaid + detail.interestPaid;
            if (totalRepaid >= minTotalPayment) {
                return false;
            }

            paymentDueTime = loan.borrowedTime + ((totalRepaid / loan.installmentAmount) + 1) * installmentPeriod;
        } else {
            paymentDueTime = loan.borrowedTime + loan.duration;
        }

        return block.timestamp > paymentDueTime + loan.gracePeriod;
    }

    /**
     * @notice Validates loan offer parameters
     * @dev Throws a require-type exception on invalid loan parameter
     * @param _amount Loan amount in liquidity tokens
     * @param _duration Loan term in seconds
     * @param _gracePeriod Loan payment grace period in seconds
     * @param _installmentAmount Minimum payment amount on each instalment in liquidity tokens
     * @param _installments The number of payment installments
     * @param _apr Annual percentage rate of this loan
     */
    function validateLoanParams(
        uint256 _amount,
        uint256 _duration,
        uint256 _gracePeriod,
        uint256 _installmentAmount,
        uint16 _installments,
        uint16 _apr
    ) private view
    {
        require(_amount >= loanTemplate.minAmount, "LoanDesk: invalid amount");
        require(
            loanTemplate.minDuration <= _duration && _duration <= loanTemplate.maxDuration,
            "LoanDesk: invalid duration"
        );
        require(Limits.MIN_LOAN_GRACE_PERIOD <= _gracePeriod && _gracePeriod <= Limits.MAX_LOAN_GRACE_PERIOD,
            "LoanDesk: invalid grace period");
        require(
            _installmentAmount == 0 || _installmentAmount >= Limits.SAFE_MIN_AMOUNT,
            "LoanDesk: invalid installment amount"
        );
        require(
            1 <= _installments && _installments <= _duration / (1 days),
            "LoanDesk: invalid number of installments"
        );
        require(Limits.SAFE_MIN_APR <= _apr && _apr <= SaplingMath.HUNDRED_PERCENT, "LoanDesk: invalid APR");
    }

    /**
     * @notice Loan balances due if paid in full at this time.
     * @param loanId ID of the loan to check the balance of
     * @return Principal outstanding, interest outstanding, and the number of interest acquired days
     */
    function loanBalanceDueWithInterest(uint256 loanId) private view returns (uint256, uint256, uint256) {
        Loan storage loan = loans[loanId];
        LoanDetail storage detail = loanDetails[loanId];

        uint256 daysPassed = countInterestDays(detail.interestPaidTillTime, block.timestamp);
        uint256 interestPercent = MathUpgradeable.mulDiv(uint256(loan.apr) * 1e18, daysPassed, 365);

        uint256 principalOutstanding = loan.amount - detail.principalAmountRepaid;
        uint256 interestOutstanding = MathUpgradeable.mulDiv(
            principalOutstanding, 
            interestPercent, 
            SaplingMath.HUNDRED_PERCENT
        ) / 1e18;

        return (principalOutstanding, interestOutstanding, daysPassed);
    }

    /**
     * @notice Loan balances payable given a max payment amount.
     * @param loanId ID of the loan to check the balance of
     * @param maxPaymentAmount Maximum liquidity token amount user has agreed to pay towards the loan
     * @return Total transfer camount, paymentAmount, interest payable, and the number of payable interest days,
     *         and the current loan balance
     */
    function payableLoanBalance(
        uint256 loanId,
        uint256 maxPaymentAmount
    )
        private
        view
        returns (uint256, uint256, uint256, uint256)
    {
        (
            uint256 principalOutstanding,
            uint256 interestOutstanding,
            uint256 interestDays
        ) = loanBalanceDueWithInterest(loanId);

        uint256 useCarryAmount = loanDetails[loanId].paymentCarry;
        uint256 balanceDue = principalOutstanding + interestOutstanding - useCarryAmount;

        uint256 transferAmount = MathUpgradeable.min(balanceDue, maxPaymentAmount);
        uint256 paymentAmount = transferAmount + useCarryAmount;

        uint256 interestPayable;
        uint256 payableInterestDays;

        if (paymentAmount >= interestOutstanding) {
            payableInterestDays = interestDays;
            interestPayable = interestOutstanding;
        } else {
            /*
             Round down payable interest amount to cover a whole number of days.

             Whole number of days the transfer amount can cover:
             payableInterestDays = transferAmount / (interestOutstanding / interestDays)

             interestPayable = (interestOutstanding / interestDays) * payableInterestDays

             Equations above are transformed into (a * b) / c format for best mulDiv() compatibility.
             */
            payableInterestDays = MathUpgradeable.mulDiv(paymentAmount, interestDays, interestOutstanding);
            interestPayable = MathUpgradeable.mulDiv(interestOutstanding, payableInterestDays, interestDays);

            /*
             Handle "small payment exploit" which unfairly reduces the principal amount by making payments smaller than
             1 day interest, while the interest on the remaining principal is outstanding.

             Do not accept leftover payments towards the principal while any daily interest is outstandig.
             */
            if (payableInterestDays < interestDays) {
                paymentAmount = interestPayable;
            }
        }

        return (transferAmount, paymentAmount, interestPayable, payableInterestDays);
    }

    /**
     * @notice Get the number of days in a time period to witch an interest can be applied.
     * @dev Returns the ceiling of the count.
     * @param timeFrom Epoch timestamp of the start of the time period.
     * @param timeTo Epoch timestamp of the end of the time period.
     * @return Ceil count of days in a time period to witch an interest can be applied.
     */
    function countInterestDays(uint256 timeFrom, uint256 timeTo) private pure returns(uint256) {
        if (timeTo <= timeFrom) {
            return 0;
        }

        uint256 countSeconds = timeTo - timeFrom;
        uint256 dayCount = countSeconds / 86400;

        if (countSeconds % 86400 > 0) {
            dayCount++;
        }

        return dayCount;
    }

    /**
     * @notice Indicates whether or not the contract can be closed in it's current state.
     * @dev Overrides a hook in SaplingManagerContext.
     * @return True if the contract is closed, false otherwise.
     */
    function canClose() internal view override returns (bool) {
        return offeredFunds == 0 && outstandingLoansCount == 0;
    }

    /**
     * @notice Indicates whether or not the contract can be opened in it's current state.
     * @dev Overrides a hook in SaplingManagerContext.
     * @return True if the conditions to open are met, false otherwise.
     */
    function canOpen() internal view override returns (bool) {
        return pool != address(0);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./SaplingContext.sol";

/**
 * @title Sapling Manager Context
 * @notice Provides manager access control, and a basic close functionality.
 * @dev Close functionality is implemented in the same fashion as Openzeppelin's Pausable. 
 */
abstract contract SaplingManagerContext is SaplingContext {

    /*
     * Pool manager role
     * 
     * @dev The value of this role should be unique for each pool. Role must be created before the pool contract 
     *      deployment, then passed during construction/initialization.
     */
    bytes32 public poolManagerRole;

    /// Flag indicating whether or not the pool is closed
    bool private _closed;

    /// Event for when the contract is closed
    event Closed(address account);

    /// Event for when the contract is reopened
    event Opened(address account);

    /// A modifier to limit access only to non-management users
    modifier onlyUser() {
        require(!isNonUserAddress(msg.sender), "SaplingManagerContext: caller is not a user");
        _;
    }

    /// Modifier to limit function access to when the contract is not closed
    modifier whenNotClosed {
        require(!_closed, "SaplingManagerContext: closed");
        _;
    }

    /// Modifier to limit function access to when the contract is closed
    modifier whenClosed {
        require(_closed, "SaplingManagerContext: not closed");
        _;
    }

    /**
     * @notice Create a new SaplingManagedContext.
     * @dev Addresses must not be 0.
     * @param _accessControl Access control contract address
     * @param _managerRole Manager role
     */
    function __SaplingManagerContext_init(
        address _accessControl,
        bytes32 _managerRole
    )
        internal
        onlyInitializing
    {
        __SaplingContext_init(_accessControl);

        /*
            Additional check for single init:
                do not init again if a non-zero value is present in the values yet to be initialized.
        */
        assert(_closed == false && poolManagerRole == 0x00);

        poolManagerRole = _managerRole;
        _closed = true;
    }

    /**
     * @notice Close the pool.
     * @dev Only the functions using whenClosed and whenNotClosed modifiers will be affected by close.
     *      Caller must have the pool manager role. Pool must be open.
     *
     *      Manager must have access to close function as the ability to unstake and withdraw all manager funds is 
     *      only guaranteed when the pool is closed and all outstanding loans resolved. 
     */
    function close() external onlyRole(poolManagerRole) whenNotClosed {
        require(canClose(), "SaplingManagerContext: cannot close the pool under current conditions");

        _closed = true;

        emit Closed(msg.sender);
    }

    /**
     * @notice Open the pool for normal operations.
     * @dev Only the functions using whenClosed and whenNotClosed modifiers will be affected by open.
     *      Caller must have the pool manager role. Pool must be closed.
     */
    function open() external onlyRole(poolManagerRole) whenClosed {
        require(canOpen(), "SaplingManagerContext: cannot open the pool under current conditions");
        _closed = false;

        emit Opened(msg.sender);
    }

    /**
     * @notice Indicates whether or not the contract is closed.
     * @return True if the contract is closed, false otherwise.
     */
    function closed() public view returns (bool) {
        return _closed;
    }

     /**
     * @notice Verify if an address has any non-user/management roles
     * @dev Overrides the same function in SaplingContext
     * @param party Address to verify
     * @return True if the address has any roles, false otherwise
     */
    function isNonUserAddress(address party) internal view override returns (bool) {
        return hasRole(poolManagerRole, party) || super.isNonUserAddress(party);
    }

    /**
     * @notice Indicates whether or not the contract can be closed in it's current state.
     * @dev A hook for the extending contract to implement.
     * @return True if the conditions of the closure are met, false otherwise.
     */
    function canClose() internal view virtual returns (bool) {
        return true;
    }

    /**
     * @notice Indicates whether or not the contract can be opened in it's current state.
     * @dev A hook for the extending contract to implement.
     * @return True if the conditions to open are met, false otherwise.
     */
    function canOpen() internal view virtual returns (bool) {
        return true;
    }

    /**
     * @dev Slots reserved for future state variables
     */
    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
 * @title LoanDesk Interface
 * @dev LoanDesk interface defining common structures and hooks for the lending pools.
 */
interface ILoanDesk {

    /**
     * Loan application statuses. Initial value is defines as 'NULL' to differentiate the unintitialized state from
     * the logical initial states.
     */
    enum LoanApplicationStatus {
        NULL,
        APPLIED,
        DENIED,
        OFFER_MADE,
        OFFER_ACCEPTED,
        OFFER_CANCELLED
    }

    /// Default loan parameter values
    struct LoanTemplate {
        
        /// Minimum allowed loan amount
        uint256 minAmount;

        /// Minimum loan duration in seconds
        uint256 minDuration;

        /// Maximum loan duration in seconds
        uint256 maxDuration;

        /// Loan payment grace period after which a loan can be defaulted
        uint256 gracePeriod;

        /// Loan APR to be applied for the new loan requests
        uint16 apr;
    }

    /// Loan application object
    struct LoanApplication {

        /// Application ID
        uint256 id;

        /// Applicant address, the borrower
        address borrower;

        /// Requested loan amount in liquidity tokens
        uint256 amount;

        /// Requested loan duration in seconds
        uint256 duration;

        /// Block timestamp
        uint256 requestedTime;

        /// Application status
        LoanApplicationStatus status;

        /// Applicant profile ID from the borrower metadata API
        string profileId;

        /// Applicant profile digest from the borrower medatata API
        string profileDigest;
    }

    /// Loan offer object
    struct LoanOffer {

        // Application ID, same as the loan application ID this offer is made for
        uint256 applicationId; 

        /// Applicant address, the borrower
        address borrower;

        /// Loan principal amount in liquidity tokens
        uint256 amount;

        /// Loan duration in seconds
        uint256 duration; 

        /// Repayment grace period in seconds
        uint256 gracePeriod;

        /// Installment amount in liquidity tokens
        uint256 installmentAmount;

        /// Installments, the minimum number of repayments
        uint16 installments; 

        /// Annual percentage rate
        uint16 apr; 

        /// Block timestamp of the offer creation/update
        uint256 offeredTime;
    }

    /**
     * Loan statuses. Initial value is defines as 'NULL' to differentiate the unintitialized state from the logical
     * initial state.
     */
    enum LoanStatus {
        NULL,
        OUTSTANDING,
        REPAID,
        DEFAULTED
    }

    /// Loan object
    struct Loan {

        /// ID, increamental, value is not linked to application ID
        uint256 id;

        /// Address of the loan desk contract this loan was created at
        address loanDeskAddress;

        // Application ID, same as the loan application ID this loan is made for
        uint256 applicationId;

        /// Recepient of the loan principal, the borrower
        address borrower;

        /// Loan principal amount in liquidity tokens
        uint256 amount;

        /// Loan duration in seconds
        uint256 duration;

        /// Repayment grace period in seconds
        uint256 gracePeriod;

        /// Installment amount in liquidity tokens
        uint256 installmentAmount;

        /// Installments, the minimum number of repayments
        uint16 installments;

        /// Annual percentage rate
        uint16 apr;

        /// Block timestamp of funds release
        uint256 borrowedTime;

        /// Loan status
        LoanStatus status;
    }

    /// Loan payment details
    struct LoanDetail {

        /// Loan ID
        uint256 loanId;

        /** 
         * Total amount repaid in liquidity tokens.
         * Total amount repaid must always equal to the sum of (principalAmountRepaid, interestPaid, paymentCarry)
         */
        uint256 totalAmountRepaid;

        /// Principal amount repaid in liquidity tokens
        uint256 principalAmountRepaid;

        /// Interest paid in liquidity tokens
        uint256 interestPaid;

        /// Payment carry 
        uint256 paymentCarry;

        /// timestamp to calculate the interest from, on the outstanding principal
        uint256 interestPaidTillTime;
    }

    /// Event for when a new loan is requested, and an application is created
    event LoanRequested(uint256 applicationId, address indexed borrower, uint256 amount);

    /// Event for when a loan request is denied
    event LoanRequestDenied(uint256 applicationId, address indexed borrower, uint256 amount);

    /// Event for when a loan offer is made
    event LoanOffered(uint256 applicationId, address indexed borrower, uint256 amount);

    /// Event for when a loan offer is updated
    event LoanOfferUpdated(uint256 applicationId, address indexed borrower, uint256 prevAmount, uint256 newAmount);

    /// Event for when a loan offer is cancelled
    event LoanOfferCancelled(uint256 applicationId, address indexed borrower, uint256 amount);

    /// Event for when a loan offer is accepted
    event LoanOfferAccepted(uint256 applicationId, address indexed borrower, uint256 amount);

    /// Event for when loan offer is accepted and the loan is borrowed
    event LoanBorrowed(uint256 loanId, address indexed borrower, uint256 applicationId);

    /// Event for when a loan payment is initiated
    event LoanRepaymentInitiated(
        uint256 loanId, 
        address borrower, 
        address payer, 
        uint256 amount, 
        uint256 interestAmount
    );

    /// Event for when a loan is fully repaid
    event LoanFullyRepaid(uint256 loanId, address indexed borrower);

    /// Event for when a loan is closed
    event LoanClosed(uint256 loanId, address indexed borrower, uint256 managerLossAmount, uint256 lenderLossAmount);

    /// Event for when a loan is defaulted
    event LoanDefaulted(uint256 loanId, address indexed borrower, uint256 managerLoss, uint256 lenderLoss);

    /// Setter event
    event MinLoanAmountSet(uint256 prevValue, uint256 newValue);

    /// Setter event
    event MinLoanDurationSet(uint256 prevValue, uint256 newValue);

    /// Setter event
    event MaxLoanDurationSet(uint256 prevValue, uint256 newValue);

    /// Setter event
    event TemplateLoanGracePeriodSet(uint256 prevValue, uint256 newValue);

    /// Setter event
    event TemplateLoanAPRSet(uint256 prevValue, uint256 newValue);

    /**
     * @notice Accessor for loan.
     * @param loanId ID of the loan
     * @return Loan struct instance for the specified loan ID.
     */
    function loanById(uint256 loanId) external view returns (Loan memory);

    /**
     * @notice Accessor for loan.
     * @param loanId ID of the loan
     * @return Loan struct instance for the specified loan ID.
     */
    function loanDetailById(uint256 loanId) external view returns (LoanDetail memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IPoolContext {

    /// Tokens configuration
    struct TokenConfig {

        /// Address of an ERC20 token managed and issued by the pool
        address poolToken;

        /// Address of an ERC20 liquidity token accepted by the pool
        address liquidityToken;

        /// decimals value retrieved from the liquidity token contract upon contract construction
        uint8 decimals;
    }

    /// Pool configuration
    struct PoolConfig {

        // Auto or pseudo-constant parameters

        /// Weighted average loan APR on the borrowed funds
        uint256 weightedAvgStrategyAPR;

        /// exit fee percentage
        uint16 exitFeePercent;

        /// An upper bound for percentage of paid interest to be allocated as protocol fee
        uint16 maxProtocolFeePercent;


        // Governance maintained parameters

        /// Minimum liquidity token amount for withdrawal requests
        uint256 minWithdrawalRequestAmount;
        
        /// Target percentage ratio of staked shares to total shares
        uint16 targetStakePercent;

        /// Percentage of paid interest to be allocated as protocol fee
        uint16 protocolFeePercent;

        /// Governance set upper bound for the manager's leveraged earn factor
        uint16 managerEarnFactorMax;


        // Pool manager maintained parameters

        /// Manager's leveraged earn factor represented as a percentage
        uint16 managerEarnFactor;

        /// Target percentage of pool funds to keep liquid.
        uint16 targetLiquidityPercent;
    }

    /// Key pool balances
    struct PoolBalance {

        /// Total liquidity tokens currently held by this contract
        uint256 tokenBalance;

        /// Current amount of liquid tokens, available to for pool strategies, withdrawals, withdrawal requests
        uint256 rawLiquidity;

        /// Current amount of liquidity tokens in the pool, including both liquid and allocated funds
        uint256 poolFunds;

        /// Current funds allocated for pool strategies
        uint256 allocatedFunds;

        /// Current funds committed to strategies such as borrowing or investing
        uint256 strategizedFunds;

        /// Withdrawal request
        uint256 withdrawalRequestedShares; 


        // Role specific balances

        /// Manager's staked shares
        uint256 stakedShares;

        /// Accumulated manager revenue from leveraged earnings, withdrawable
        uint256 managerRevenue;

        /// Accumulated protocol revenue, withdrawable
        uint256 protocolRevenue;
    }

    /// Per user state for all of the user's withdrawal requests
    struct WithdrawalRequestState {
        uint256 sharesLocked;
        uint8 countOutstanding;
    }

    /// Helper struct for APY views
    struct APYBreakdown {

        /// Total pool APY
        uint16 totalPoolAPY;

        /// part of the pool APY allocated as protool revenue
        uint16 protocolRevenueComponent;

        /// part of the pool APY allocated as manager revenue
        uint16 managerRevenueComponent;

        /// part of the pool APY allocated as lender APY. Lender APY also applies manager's non-revenue yield on stake.
        uint16 lenderComponent;
    }

    /// Event for when the lender capital is lost due to defaults
    event UnstakedLoss(uint256 amount);

    /// Event for when the Manager's staked assets are depleted due to defaults
    event StakedAssetsDepleted();

    /// Event for when lender funds are deposited
    event FundsDeposited(address wallet, uint256 amount, uint256 tokensIssued);

    /// Event for when lender funds are withdrawn
    event FundsWithdrawn(address wallet, uint256 amount, uint256 tokensRedeemed);

    /// Event for when pool manager funds are staked
    event FundsStaked(address wallet, uint256 amount, uint256 tokensIssued);

    /// Event for when pool manager funds are unstaked
    event FundsUnstaked(address wallet, uint256 amount, uint256 tokensRedeemed);

    /// Event for when a non user revenue is withdrawn
    event RevenueWithdrawn(address wallet, uint256 amount);

    /// Setter event
    event TargetStakePercentSet(uint16 prevValue, uint16 newValue);

    /// Setter event
    event TargetLiqudityPercentSet(uint16 prevValue, uint16 newValue);

    /// Setter event
    event ProtocolFeePercentSet(uint16 prevValue, uint16 newValue);

    /// Setter event
    event ManagerEarnFactorMaxSet(uint16 prevValue, uint16 newValue);

    /// Setter event
    event ManagerEarnFactorSet(uint16 prevValue, uint16 newValue);

    /**
     * @notice Get liquidity token value of shares.
     * @param poolTokens Pool token amount.
     * @return Converted liqudity token value.
     */
    function tokensToFunds(uint256 poolTokens) external view returns (uint256);

    /**
     * @notice Get pool token value of liquidity tokens.
     * @param liquidityTokens Amount of liquidity tokens.
     * @return Converted pool token value.
     */
    function fundsToTokens(uint256 liquidityTokens) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
 * @title LendingPool Interface
 * @dev This interface has all LendingPool events, structs, and LoanDesk function hooks.
 */
interface ILendingPool {

    /// Event for when a new loan desk is set
    event LoanDeskSet(address from, address to);

    /// Event whn loan funds are released after accepting a loan offer
    event LoanFundsReleased(uint256 loanId, address indexed borrower, uint256 amount);

    /// Event for when a loan is closed
    event LoanClosed(uint256 loanId, address indexed borrower, uint256 managerLossAmount, uint256 lenderLossAmount);

    /// Event for when a loan is defaulted
    event LoanDefaulted(uint256 loanId, address indexed borrower, uint256 managerLoss, uint256 lenderLoss);

    /// Event for when a liquidity is allocated for a loan offer
    event OfferLiquidityAllocated(uint256 amount);

    /// Event for when the liquidity is adjusted for a loan offer
    event OfferLiquidityUpdated(uint256 prevAmount, uint256 newAmount);

    /// Event for when a loan repayments are made
    event LoanRepaymentConfirmed(
        uint256 loanId, 
        address borrower, 
        address payer, 
        uint256 amount, 
        uint256 interestAmount
    );

    /**
     * @dev Hook for a new loan offer.
     *      Caller must be the LoanDesk.
     * @param amount Loan offer amount.
     */
    function onOffer(uint256 amount) external;

    /**
     * @dev Hook for a loan offfer amount update.
     * @param prevAmount The original, now previous, offer amount.
     * @param amount New offer amount. Cancelled offer must register an amount of 0 (zero).
     */
    function onOfferUpdate(uint256 prevAmount, uint256 amount) external;

    /**
     * @dev Hook for borrowing a loan. Caller must be the loan desk.
     *
     *      Parameters besides the loanId exists simply to avoid rereading it from the caller via additinal inter 
     *      contract call. Avoiding loop call reduces gas, contract bytecode size, and reduces the risk of reentrancy.
     *
     * @param loanId ID of the loan being borrowed
     * @param borrower Wallet address of the borrower, same as loan.borrower
     * @param amount Loan principal amount, same as loan.amount
     * @param apr Loan annual percentage rate, same as loan.apr
     */
    function onBorrow(uint256 loanId, address borrower, uint256 amount, uint16 apr) external;

     /**
     * @dev Hook for repayments. Caller must be the LoanDesk. 
     *      
     *      Parameters besides the loanId exists simply to avoid rereading it from the caller via additional inter 
     *      contract call. Avoiding loop call reduces gas, contract bytecode size, and reduces the risk of reentrancy.
     *
     * @param loanId ID of the loan which has just been borrowed
     * @param borrower Borrower address
     * @param payer Actual payer address
     * @param apr Loan apr
     * @param transferAmount Amount chargeable
     * @param paymentAmount Logical payment amount, may be different to the transfer amount due to a payment carry
     * @param interestPayable Amount of interest paid, this value is already included in the payment amount
     */
    function onRepay(
        uint256 loanId, 
        address borrower, 
        address payer, 
        uint16 apr,
        uint256 transferAmount, 
        uint256 paymentAmount, 
        uint256 interestPayable
    ) external;

    /**
     * @dev Hook for closing a loan. Caller must be the LoanDesk. Closing a loan will repay the outstanding principal 
     *      using the pool manager's revenue and/or staked funds. If these funds are not sufficient, the lenders will 
     *      share the loss.
     * @param loanId ID of the loan to close
     * @param apr Loan apr
     * @param amountRepaid Amount repaid based on outstanding payment carry
     * @param remainingDifference Principal amount remaining to be resolved to close the loan
     * @return Amount reimbursed by the pool manager funds
     */
    function onCloseLoan(
        uint256 loanId,
        uint16 apr,
        uint256 amountRepaid, 
        uint256 remainingDifference
    )
     external
     returns (uint256);

    /**
     * @dev Hook for defaulting a loan. Caller must be the LoanDesk. Defaulting a loan will cover the loss using 
     * the staked funds. If these funds are not sufficient, the lenders will share the loss.
     * @param loanId ID of the loan to default
     * @param apr Loan apr
     * @param carryAmountUsed Amount of payment carry repaid 
     * @param loss Loss amount to resolve
     */
    function onDefault(
        uint256 loanId,
        uint16 apr,
        uint256 carryAmountUsed,
        uint256 loss
    )
     external 
     returns (uint256, uint256);

    /**
     * @notice View indicating whether or not a given loan can be offered by the manager.
     * @dev Hook for checking if the lending pool can provide liquidity for the total offered loans amount.
     * @param totalOfferedAmount Total sum of offered loan amount including outstanding offers
     * @return True if the pool has sufficient lending liquidity, false otherwise
     */
    function canOffer(uint256 totalOfferedAmount) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * Sapling math library
 */
library SaplingMath {
    
    /// The mumber of decimal digits in percentage values
    uint16 public constant PERCENT_DECIMALS = 1;

    /// A constant representing 100%
    uint16 public constant HUNDRED_PERCENT = uint16(100 * 10 ** PERCENT_DECIMALS);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * Math safe and intended limits
 */
library Limits {
    
    /// Math safe minimum loan duration in seconds
    uint256 public constant SAFE_MIN_DURATION = 1 days;

    /// Math safe maximum loan duration in seconds
    uint256 public constant SAFE_MAX_DURATION = 51 * 365 days;

    /// Minimum allowed loan payment grace period
    uint256 public constant MIN_LOAN_GRACE_PERIOD = 3 days;

    /// Maximum allowed loan payment grace period
    uint256 public constant MAX_LOAN_GRACE_PERIOD = 365 days;

    /// Safe minimum for APR values
    uint16 public constant SAFE_MIN_APR = 0; // 0%

    /// Math safe minimum loan amount, raw value
    uint256 public constant SAFE_MIN_AMOUNT = 10 ** 6;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "../lib/SaplingRoles.sol";

/**
 * @title Sapling Context
 * @notice Provides reference to protocol level access control, and basic pause
 *         functionality by extending OpenZeppelin's Pausable contract.
 */
abstract contract SaplingContext is Initializable, PausableUpgradeable {

    /// Protocol access control
    address public accessControl;

    /// Modifier to limit function access to a specific role
    modifier onlyRole(bytes32 role) {
        require(hasRole(role, msg.sender), "SaplingContext: unauthorized");
        _;
    }

    /**
     * @notice Creates a new SaplingContext.
     * @dev Addresses must not be 0.
     * @param _accessControl Protocol level access control contract address
     */
    function __SaplingContext_init(address _accessControl) internal onlyInitializing {
        __Pausable_init();

        /*
            Additional check for single init:
                do not init again if a non-zero value is present in the values yet to be initialized.
        */
        assert(accessControl == address(0));

        require(_accessControl != address(0), "SaplingContext: access control contract address is not set");
        
        accessControl = _accessControl;
    }

    /**
     * @notice Pause the contract.
     * @dev Only the functions using whenPaused and whenNotPaused modifiers will be affected by pause.
     *      Caller must have the PAUSER_ROLE. 
     */
    function pause() external onlyRole(SaplingRoles.PAUSER_ROLE) {
        _pause();
    }

    /**
     * @notice Resume the contract.
     * @dev Only the functions using whenPaused and whenNotPaused modifiers will be affected by unpause.
     *      Caller must have the PAUSER_ROLE. 
     *      
     */
    function unpause() external onlyRole(SaplingRoles.PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @notice Verify if an address has any non-user/management roles
     * @dev When overriding, return "contract local verification result" AND super.isNonUserAddress(party).
     * @param party Address to verify
     * @return True if the address has any roles, false otherwise
     */
    function isNonUserAddress(address party) internal view virtual returns (bool) {
        return hasRole(SaplingRoles.GOVERNANCE_ROLE, party) 
            || hasRole(SaplingRoles.TREASURY_ROLE, party)
            || hasRole(SaplingRoles.PAUSER_ROLE, party);
    }

    /**
     * @notice Verify if an address has a specific role.
     * @param role Role to check against
     * @param party Address to verify
     * @return True if the address has the specified role, false otherwise
     */
    function hasRole(bytes32 role, address party) internal view returns (bool) {
        return IAccessControl(accessControl).hasRole(role, party);
    }

    /**
     * @dev Slots reserved for future state variables
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * Protocol level Sapling roles
 */
library SaplingRoles {
    
    /// Admin of the core access control 
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /// Protocol governance role
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");

    /// Protocol treasury role
    bytes32 public constant TREASURY_ROLE = keccak256("TREASURY_ROLE");

    /**
     * @dev Pauser can be governance or an entity/bot designated as a monitor that 
     *      enacts a pause on emergencies or anomalies.
     *      
     *      PAUSER_ROLE is a protocol level role and should not be granted to pool managers or to users. Doing so would 
     *      give the role holder the ability to pause not just their pool, but any contract within the protocol.
     */
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}