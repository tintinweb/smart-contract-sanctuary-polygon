// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./context/SaplingPoolContext.sol";
import "./interfaces/ILoanDesk.sol";
import "./interfaces/ILoanDeskOwner.sol";

/**
 * @title Sapling Lending Pool
 * @dev Extends SaplingPoolContext with lending strategy.
 */
contract SaplingLendingPool is ILoanDeskOwner, SaplingPoolContext {

    using SafeMathUpgradeable for uint256;

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

    /// Loan object template
    struct Loan {
        uint256 id;
        address loanDeskAddress;
        uint256 applicationId;
        address borrower;
        uint256 amount;
        uint256 duration;
        uint256 gracePeriod;
        uint256 installmentAmount;
        uint16 installments;
        uint16 apr;
        uint256 borrowedTime;
        LoanStatus status;
    }

    /// Loan payment details object template
    struct LoanDetail {
        uint256 loanId;
        uint256 totalAmountRepaid;
        uint256 principalAmountRepaid;
        uint256 interestPaid;
        uint256 interestPaidTillTime;
        uint256 lastPaymentTime;
    }

    /// Individual borrower statistics
    struct BorrowerStats {

        /// Wallet address of the borrower
        address borrower;

        /// All time loan borrow count
        uint256 countBorrowed;

        /// All time loan closure count
        uint256 countRepaid;

        /// All time loan default count
        uint256 countDefaulted;

        /// Current outstanding loan count
        uint256 countOutstanding;

        /// Outstanding loan borrowed amount
        uint256 amountBorrowed;

        /// Outstanding loan repaid principal amount
        uint256 amountBaseRepaid;

        /// Outstanding loan paid interest amount
        uint256 amountInterestPaid;

        /// Most recent loanId
        uint256 recentLoanId;
    }

    /// Address of the loan desk contract
    address public loanDesk;

    /// Loans by loan ID
    mapping(uint256 => Loan) public loans;

    /// LoanDetails by loan ID
    mapping(uint256 => LoanDetail) public loanDetails;

    /// Borrower statistics by address
    mapping(address => BorrowerStats) public borrowerStats;

    /// Event for when a new loan desk is set
    event LoanDeskSet(address from, address to);

    /// Event for when loan offer is accepted and the loan is borrowed
    event LoanBorrowed(uint256 loanId, address indexed borrower, uint256 applicationId);

    /// Event for when a loan is fully repaid
    event LoanRepaid(uint256 loanId, address indexed borrower);

    /// Event for when a loan is defaulted
    event LoanDefaulted(uint256 loanId, address indexed borrower, uint256 amountLost);

    /// A modifier to limit access to when a loan has the specified status
    modifier loanInStatus(uint256 loanId, LoanStatus status) {
        require(loans[loanId].status == status, "SaplingLendingPool: not found or invalid loan status");
        _;
    }

    /// A modifier to limit access only to the loan desk contract
    modifier onlyLoanDesk() {
        require(msg.sender == loanDesk, "SaplingLendingPool: caller is not the LoanDesk");
        _;
    }

    /**
     * @dev Disable initializers
     */
    function disableIntitializers() external onlyGovernance {
        _disableInitializers();
    }

    /**
     * @notice Creates a Sapling pool.
     * @dev Addresses must not be 0.
     * @param _poolToken ERC20 token contract address to be used as the pool issued token.
     * @param _liquidityToken ERC20 token contract address to be used as pool liquidity currency.
     * @param _governance Governance address
     * @param _treasury Treasury wallet address
     * @param _manager Manager address
     */
    function initialize(
        address _poolToken,
        address _liquidityToken,
        address _governance,
        address _treasury,
        address _manager
    )
        public
        initializer
    {
        __SaplingPoolContext_init(_poolToken, _liquidityToken, _governance, _treasury, _manager);
    }

    /**
     * @notice Links a new loan desk for the pool to use. Intended for use upon initial pool deployment.
     * @dev Caller must be the governance.
     * @param _loanDesk New LoanDesk address
     */
    function setLoanDesk(address _loanDesk) external onlyGovernance {
        address prevLoanDesk = loanDesk;
        loanDesk = _loanDesk;
        emit LoanDeskSet(prevLoanDesk, loanDesk);
    }

    /**
     * @notice Accept a loan offer and withdraw funds
     * @dev Caller must be the borrower of the loan in question.
     *      The loan must be in OFFER_MADE status.
     * @param appId ID of the loan application to accept the offer of
     */
    function borrow(uint256 appId) external whenNotClosed whenNotPaused {

        require(
            ILoanDesk(loanDesk).applicationStatus(appId) == ILoanDesk.LoanApplicationStatus.OFFER_MADE,
            "SaplingLendingPool: invalid offer status"
        );

        ILoanDesk.LoanOffer memory offer = ILoanDesk(loanDesk).loanOfferById(appId);

        require(offer.borrower == msg.sender, "SaplingLendingPool: msg.sender is not the borrower on this loan");
        ILoanDesk(loanDesk).onBorrow(appId);

        borrowerStats[offer.borrower].countOutstanding++;
        borrowerStats[offer.borrower].amountBorrowed = borrowerStats[offer.borrower].amountBorrowed.add(offer.amount);

        uint256 loanId = getNextStrategyId();

        loans[loanId] = Loan({
            id: loanId,
            loanDeskAddress: loanDesk,
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
            interestPaidTillTime: block.timestamp,
            lastPaymentTime: 0
        });

        borrowerStats[offer.borrower].recentLoanId = loanId;

        uint256 prevStrategizedFunds = strategizedFunds;
        allocatedFunds = allocatedFunds.sub(offer.amount);
        strategizedFunds = strategizedFunds.add(offer.amount);

        weightedAvgStrategyAPR = prevStrategizedFunds
            .mul(weightedAvgStrategyAPR)
            .add(offer.amount.mul(offer.apr))
            .div(strategizedFunds);

        tokenBalance = tokenBalance.sub(offer.amount);
        bool success = IERC20(liquidityToken).transfer(msg.sender, offer.amount);
        require(success, "SaplingLendingPool: ERC20 transfer failed");

        emit LoanBorrowed(loanId, offer.borrower, appId);
    }

    /**
     * @notice Make a payment towards a loan.
     * @dev Caller must be the borrower.
     *      Loan must be in OUTSTANDING status.
     *      Only the necessary sum is charged if amount exceeds amount due.
     *      Amount charged will not exceed the amount parameter.
     * @param loanId ID of the loan to make a payment towards.
     * @param amount Payment amount in tokens.
     * @return A pair of total amount charged including interest, and the interest charged.
     */
    function repay(uint256 loanId, uint256 amount) external returns (uint256, uint256) {
        // require the payer and the borrower to be the same to avoid mispayment
        require(loans[loanId].borrower == msg.sender, "SaplingLendingPool: payer is not the borrower");

        return repayBase(loanId, amount);
    }

    /**
     * @notice Make a payment towards a loan on behalf of a borrower.
     * @dev Loan must be in OUTSTANDING status.
     *      Only the necessary sum is charged if amount exceeds amount due.
     *      Amount charged will not exceed the amount parameter.
     * @param loanId ID of the loan to make a payment towards.
     * @param amount Payment amount in tokens.
     * @param borrower address of the borrower to make a payment on behalf of.
     * @return A pair of total amount charged including interest, and the interest charged.
     */
    function repayOnBehalf(uint256 loanId, uint256 amount, address borrower ) external returns (uint256, uint256) {
        // require the borrower being paid on behalf off and the loan borrower to be the same to avoid mispayment
        require(loans[loanId].borrower == borrower, "SaplingLendingPool: invalid borrower");

        return repayBase(loanId, amount);
    }

    /**
     * @notice Default a loan.
     * @dev Loan must be in OUTSTANDING status.
     *      Caller must be the manager.
     *      canDefault(loanId, msg.sender) must return 'true'.
     * @param loanId ID of the loan to default
     */
    function defaultLoan(
        uint256 loanId
    )
        public
        managerOrApprovedOnInactive
        loanInStatus(loanId, LoanStatus.OUTSTANDING)
        whenNotPaused
    {
        require(canDefault(loanId, msg.sender), "SaplingLendingPool: cannot defaulted this loan at this time");

        Loan storage loan = loans[loanId];
        LoanDetail storage loanDetail = loanDetails[loanId];

        loan.status = LoanStatus.DEFAULTED;
        borrowerStats[loan.borrower].countDefaulted++;
        borrowerStats[loan.borrower].countOutstanding--;

        (, uint256 loss) = loan.amount.trySub(loanDetail.totalAmountRepaid);

        emit LoanDefaulted(loanId, loan.borrower, loss);

        borrowerStats[loan.borrower].amountBorrowed = borrowerStats[loan.borrower].amountBorrowed.sub(loan.amount);
        borrowerStats[loan.borrower].amountBaseRepaid = borrowerStats[loan.borrower].amountBaseRepaid
            .sub(loanDetail.principalAmountRepaid);
        borrowerStats[loan.borrower].amountInterestPaid = borrowerStats[loan.borrower].amountInterestPaid
            .sub(loanDetail.interestPaid);

        if (loss > 0) {
            uint256 lostShares = tokensToShares(loss);
            uint256 remainingLostShares = lostShares;

            poolFunds = poolFunds.sub(loss);

            if (stakedShares > 0) {
                uint256 stakedShareLoss = MathUpgradeable.min(lostShares, stakedShares);
                remainingLostShares = lostShares.sub(stakedShareLoss);
                stakedShares = stakedShares.sub(stakedShareLoss);
                updatePoolLimit();

                //burn manager's shares
                IPoolToken(poolToken).burn(address(this), stakedShareLoss);

                if (stakedShares == 0) {
                    emit StakedAssetsDepleted();
                }
            }

            if (remainingLostShares > 0) {
                emit UnstakedLoss(loss.sub(sharesToTokens(remainingLostShares)));
            }
        }

        if (loanDetail.principalAmountRepaid < loan.amount) {
            uint256 baseAmountLost = loan.amount.sub(loanDetail.principalAmountRepaid);
            strategizedFunds = strategizedFunds.sub(baseAmountLost);

            updateAvgStrategyApr(baseAmountLost, loan.apr);
        }
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
        onlyManager
        loanInStatus(loanId, LoanStatus.OUTSTANDING)
        whenNotPaused
        nonReentrant
    {
        Loan storage loan = loans[loanId];
        LoanDetail storage loanDetail = loanDetails[loanId];
        BorrowerStats storage stats = borrowerStats[loan.borrower];

        uint256 remainingDifference = loanDetail.principalAmountRepaid < loan.amount
            ? loan.amount.sub(loanDetail.principalAmountRepaid)
            : 0;

        uint256 amountRepaid = 0;

        // charge manager's revenue
        if (remainingDifference > 0 && nonUserRevenues[manager] > 0) {
            uint256 amountChargeable = MathUpgradeable.min(remainingDifference, nonUserRevenues[manager]);

            nonUserRevenues[manager] = nonUserRevenues[manager].sub(amountChargeable);

            remainingDifference = remainingDifference.sub(amountChargeable);
            amountRepaid = amountRepaid.add(amountChargeable);
        }

        // charge manager's stake
        if (remainingDifference > 0 && stakedShares > 0) {
            uint256 stakedBalance = sharesToTokens(stakedShares);
            uint256 amountChargeable = MathUpgradeable.min(remainingDifference, stakedBalance);
            uint256 stakeChargeable = tokensToShares(amountChargeable);

            stakedShares = stakedShares.sub(stakeChargeable);
            updatePoolLimit();

            IPoolToken(poolToken).burn(address(this), stakeChargeable);

            if (stakedShares == 0) {
                emit StakedAssetsDepleted();
            }

            remainingDifference = remainingDifference.sub(amountChargeable);
            amountRepaid = amountRepaid.add(amountChargeable);
        }

        if (amountRepaid > 0) {
            strategizedFunds = strategizedFunds.sub(amountRepaid);
            poolLiquidity = poolLiquidity.add(amountRepaid);

            loanDetail.totalAmountRepaid = loanDetail.totalAmountRepaid.add(amountRepaid);
            loanDetail.principalAmountRepaid = loanDetail.principalAmountRepaid.add(amountRepaid);
            loanDetail.lastPaymentTime = block.timestamp;

            stats.amountBaseRepaid = stats.amountBaseRepaid.add(amountRepaid);
        }

        // charge pool (close loan and reduce borrowed funds/poolfunds)
        if (remainingDifference > 0) {
            strategizedFunds = strategizedFunds.sub(remainingDifference);
            poolFunds = poolFunds.sub(remainingDifference);
        }

        loan.status = LoanStatus.REPAID; // Note: add and switch to CLOSED status in next migration version of the pool

        //update stats
        stats.countRepaid++;
        stats.countOutstanding--;
        stats.amountBorrowed = stats.amountBorrowed.sub(loan.amount);
        stats.amountBaseRepaid = stats.amountBaseRepaid.sub(loanDetail.principalAmountRepaid);
        stats.amountInterestPaid = stats.amountInterestPaid.sub(loanDetail.interestPaid);

        updateAvgStrategyApr(amountRepaid.add(remainingDifference), loan.apr);
    }

    /**
     * @notice Handles liquidity state changes on a loan offer.
     * @dev Hook to be called when a new loan offer is made.
     *      Caller must be the LoanDesk.
     * @param amount Loan offer amount.
     */
    function onOffer(uint256 amount) external override onlyLoanDesk {
        require(strategyLiquidity() >= amount, "SaplingLendingPool: insufficient liquidity");
        poolLiquidity = poolLiquidity.sub(amount);
        allocatedFunds = allocatedFunds.add(amount);
    }

    /**
     * @notice Handles liquidity state changes on a loan offer update.
     * @dev Hook to be called when a loan offer amount is updated. Amount update can be due to offer update or
     *      cancellation. Caller must be the LoanDesk.
     * @param prevAmount The original, now previous, offer amount.
     * @param amount New offer amount. Cancelled offer must register an amount of 0 (zero).
     */
    function onOfferUpdate(uint256 prevAmount, uint256 amount) external onlyLoanDesk {
        require(strategyLiquidity().add(prevAmount) >= amount, "SaplingLendingPool: insufficient liquidity");

        poolLiquidity = poolLiquidity.add(prevAmount).sub(amount);
        allocatedFunds = allocatedFunds.sub(prevAmount).add(amount);
    }

    /**
     * @notice View indicating whether or not a given loan can be offered by the manager.
     * @dev Hook for checking if the lending pool can provide liquidity for the total offered loans amount.
     * @param totalOfferedAmount Total sum of offered loan amount including outstanding offers
     * @return True if the pool has sufficient lending liquidity, false otherwise
     */
    function canOffer(uint256 totalOfferedAmount) external view override returns (bool) {
        return isPoolFunctional() && strategyLiquidity().add(allocatedFunds) >= totalOfferedAmount;
    }

    /**
     * @notice Check if the pool can lend based on the current stake levels.
     * @return True if the staked funds provide at least a minimum ratio to the pool funds, false otherwise.
     */
    function poolCanLend() external view returns (bool) {
        return isPoolFunctional();
    }

    /**
     * @notice Count of all loan requests in this pool.
     * @return Loans count.
     */
    function loansCount() external view returns(uint256) {
        return strategyCount();
    }

    /**
     * @notice Current pool funds borrowed.
     * @return Amount of funds borrowed in liquidity tokens.
     */
    function borrowedFunds() external view returns(uint256) {
        return strategizedFunds;
    }

    /**
     * @notice View indicating whether or not a given loan qualifies to be defaulted by a given caller.
     * @param loanId ID of the loan to check
     * @param caller An address that intends to call default() on the loan
     * @return True if the given loan can be defaulted, false otherwise
     */
    function canDefault(uint256 loanId, address caller) public view returns (bool) {
        if (caller != manager && !authorizedOnInactiveManager(caller)) {
            return false;
        }

        Loan storage loan = loans[loanId];

        if (loan.status != LoanStatus.OUTSTANDING) {
            return false;
        }

        uint256 fxBandPercent = 200; //20%

        uint256 paymentDueTime;

        if (loan.installments > 1) {
            uint256 installmentPeriod = loan.duration.div(loan.installments);
            uint256 pastInstallments = block.timestamp.sub(loan.borrowedTime).div(installmentPeriod);
            uint256 minTotalPayment = MathUpgradeable.mulDiv(
                loan.installmentAmount.mul(pastInstallments),
                fxBandPercent,
                oneHundredPercent
            );

            LoanDetail storage detail = loanDetails[loanId];
            uint256 totalRepaid = detail.principalAmountRepaid + detail.interestPaid;
            if (totalRepaid >= minTotalPayment) {
                return false;
            }

            paymentDueTime = loan.borrowedTime + (totalRepaid.div(loan.installmentAmount) + 1) * installmentPeriod;
        } else {
            paymentDueTime = loan.borrowedTime + loan.duration;
        }

        return block.timestamp > (
            paymentDueTime + loan.gracePeriod + (caller == manager ? 0 : MANAGER_INACTIVITY_GRACE_PERIOD)
        );
    }

    /**
     * @notice Loan balance due including interest if paid in full at this time.
     * @dev Loan must be in OUTSTANDING status.
     * @param loanId ID of the loan to check the balance of
     * @return Total amount due with interest on this loan
     */
    function loanBalanceDue(uint256 loanId) public view loanInStatus(loanId, LoanStatus.OUTSTANDING) returns(uint256) {
        (uint256 principalOutstanding, uint256 interestOutstanding, ) = loanBalanceDueWithInterest(loanId);
        return principalOutstanding.add(interestOutstanding);
    }

    /**
     * @notice Transfer the previous treasury wallet's accumulated fees to current treasury wallet.
     * @dev Overrides a hook in SaplingContext.
     * @param from Address of the previous treasury wallet.
     */
    function afterTreasuryWalletTransfer(address from) internal override {
        require(from != address(0), "SaplingLendingPool: invalid from address");
        nonUserRevenues[treasury] = nonUserRevenues[treasury].add(nonUserRevenues[from]);
        nonUserRevenues[from] = 0;
    }

    /**
     * @notice Make a payment towards a loan.
     * @dev Loan must be in OUTSTANDING status.
     *      Only the necessary sum is charged if amount exceeds amount due.
     *      Amount charged will not exceed the amount parameter.
     * @param loanId ID of the loan to make a payment towards
     * @param amount Payment amount in tokens
     * @return A pair of total amount charged including interest, and the interest charged
     */
    function repayBase(uint256 loanId, uint256 amount) internal nonReentrant returns (uint256, uint256) {

        Loan storage loan = loans[loanId];
        require(
            loan.id == loanId && loan.status == LoanStatus.OUTSTANDING,
            "SaplingLendingPool: not found or invalid loan status"
        );


        uint256 transferAmount;
        uint256 interestPayable;
        uint256 payableInterestDays;

        {
            (
                uint256 _transferAmount,
                uint256 _interestPayable,
                uint256 _payableInterestDays,
                uint256 _loanBalanceDue
            ) = payableLoanBalance(loanId, amount);

            transferAmount = _transferAmount;
            interestPayable = _interestPayable;
            payableInterestDays = _payableInterestDays;

            // enforce a small minimum payment amount, except for the last payment equal to the total amount due
            require(
                transferAmount >= oneToken || transferAmount == _loanBalanceDue,
                "SaplingLendingPool: payment amount is less than the required minimum"
            );
        }

        // charge 'amount' tokens from msg.sender
        bool success = IERC20(liquidityToken).transferFrom(msg.sender, address(this), transferAmount);
        require(success, "SaplingLendingPool: ERC20 transfer has failed");
        tokenBalance = tokenBalance.add(transferAmount);

        uint256 principalPaid;
        if (interestPayable == 0) {
            principalPaid = transferAmount;
            poolLiquidity = poolLiquidity.add(transferAmount);
        } else {
            principalPaid = transferAmount.sub(interestPayable);

            //share revenue to treasury
            uint256 protocolEarnedInterest = MathUpgradeable.mulDiv(
                interestPayable,
                protocolFeePercent,
                oneHundredPercent
            );

            nonUserRevenues[treasury] = nonUserRevenues[treasury].add(protocolEarnedInterest);

            //share revenue to manager
            uint256 currentStakePercent = MathUpgradeable.mulDiv(
                stakedShares,
                oneHundredPercent,
                IERC20(poolToken).totalSupply()
            );

            uint256 managerEarningsPercent = MathUpgradeable.mulDiv(
                currentStakePercent,
                managerExcessLeverageComponent,
                oneHundredPercent
            );

            uint256 managerEarnedInterest = MathUpgradeable.mulDiv(
                interestPayable.sub(protocolEarnedInterest),
                managerEarningsPercent,
                managerEarningsPercent.add(oneHundredPercent)
            );

            nonUserRevenues[manager] = nonUserRevenues[manager].add(managerEarnedInterest);

            poolLiquidity = poolLiquidity.add(transferAmount.sub(protocolEarnedInterest.add(managerEarnedInterest)));
            poolFunds = poolFunds.add(interestPayable.sub(protocolEarnedInterest.add(managerEarnedInterest)));

            updatePoolLimit();
        }

        LoanDetail storage loanDetail = loanDetails[loanId];
        loanDetail.totalAmountRepaid = loanDetail.totalAmountRepaid.add(transferAmount);
        loanDetail.principalAmountRepaid = loanDetail.principalAmountRepaid.add(principalPaid);
        loanDetail.lastPaymentTime = block.timestamp;
        loanDetail.interestPaidTillTime = loanDetail.interestPaidTillTime.add(payableInterestDays.mul(86400));

        {
            BorrowerStats storage stats = borrowerStats[loan.borrower];
            stats.amountBaseRepaid = stats.amountBaseRepaid.add(principalPaid);

            if (interestPayable != 0) {
                loanDetail.interestPaid = loanDetail.interestPaid.add(interestPayable);

                stats.amountInterestPaid = stats.amountInterestPaid
                .add(interestPayable);
            }

            strategizedFunds = strategizedFunds.sub(principalPaid);

            if (loanDetail.principalAmountRepaid >= loan.amount) {
                loan.status = LoanStatus.REPAID;
                stats.countRepaid++;
                stats.countOutstanding--;
                stats.amountBorrowed = stats.amountBorrowed.sub(loan.amount);
                stats.amountBaseRepaid = stats.amountBaseRepaid
                    .sub(loanDetail.principalAmountRepaid);
                stats.amountInterestPaid = stats.amountInterestPaid
                    .sub(loanDetail.interestPaid);
            }
        }

        updateAvgStrategyApr(principalPaid, loan.apr);

        return (transferAmount, interestPayable);
    }

    /**
     * @notice Loan balances due if paid in full at this time.
     * @param loanId ID of the loan to check the balance of
     * @return Principal outstanding, interest outstanding, and the number of interest acquired days
     */
    function loanBalanceDueWithInterest(uint256 loanId) internal view returns (uint256, uint256, uint256) {
        Loan storage loan = loans[loanId];
        LoanDetail storage detail = loanDetails[loanId];

        uint256 daysPassed = countInterestDays(detail.interestPaidTillTime, block.timestamp);
        uint256 interestPercent = MathUpgradeable.mulDiv(loan.apr, daysPassed, 365);

        uint256 principalOutstanding = loan.amount.sub(detail.principalAmountRepaid);
        uint256 interestOutstanding = MathUpgradeable.mulDiv(principalOutstanding, interestPercent, oneHundredPercent);

        return (principalOutstanding, interestOutstanding, daysPassed);
    }

    /**
     * @notice Loan balances payable given a max payment amount.
     * @param loanId ID of the loan to check the balance of
     * @param maxPaymentAmount Maximum liquidity token amount user has agreed to pay towards the loan
     * @return Total amount payable, interest payable, and the number of payable interest days
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

        uint256 transferAmount = MathUpgradeable.min(principalOutstanding.add(interestOutstanding), maxPaymentAmount);

        uint256 interestPayable;
        uint256 payableInterestDays;

        if (transferAmount >= interestOutstanding) {
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
            payableInterestDays = MathUpgradeable.mulDiv(transferAmount, interestDays, interestOutstanding);
            interestPayable = MathUpgradeable.mulDiv(interestOutstanding, payableInterestDays, interestDays);

            /*
             Handle "small payment exploit" which unfairly reduces the principal amount by making payments smaller than
             1 day interest, while the interest on the remaining principal is outstanding.

             Do not accept leftover payments towards the principal while any daily interest is outstandig.
             */
            if (payableInterestDays < interestDays) {
                transferAmount = interestPayable;
            }
        }

        return (transferAmount, interestPayable, payableInterestDays, principalOutstanding.add(interestOutstanding));
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

        uint256 countSeconds = timeTo.sub(timeFrom);
        uint256 dayCount = countSeconds.div(86400);

        if (countSeconds.mod(86400) > 0) {
            dayCount++;
        }

        return dayCount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../interfaces/IPoolToken.sol";
import "./SaplingManagerContext.sol";

/**
 * @title Sapling Pool Context
 * @notice Provides common pool functionality with lender deposits, manager's first loss capital staking,
 *         and reward distribution.
 */
abstract contract SaplingPoolContext is SaplingManagerContext, ReentrancyGuardUpgradeable {

    using SafeMathUpgradeable for uint256;

    /// Address of an ERC20 token managed and issued by the pool
    address public poolToken;

    /// Address of an ERC20 liquidity token accepted by the pool
    address public liquidityToken;

    /// tokenDecimals value retrieved from the liquidity token contract upon contract construction
    uint8 public tokenDecimals;

    /// A value representing 1.0 token amount, padded with zeros for decimals
    uint256 public oneToken;

    /// Total liquidity tokens currently held by this contract
    uint256 public tokenBalance;

    /// MAX amount of liquidity tokens allowed in the pool based on staked assets
    uint256 public poolFundsLimit;

    /// Current amount of liquidity tokens in the pool, including both liquid and allocated funds
    uint256 public poolFunds;

    /// Current amount of liquid tokens, available to for pool strategies or withdrawals
    uint256 public poolLiquidity;

    /// Current funds allocated for pool strategies
    uint256 public allocatedFunds;

    /// Current funds committed to strategies such as borrowing or investing
    uint256 public strategizedFunds;

    /// Manager's staked shares
    uint256 public stakedShares;

    /// Target percentage ratio of staked shares to total shares
    uint16 public targetStakePercent;

    /// Target percentage of pool funds to keep liquid.
    uint16 public targetLiquidityPercent;

    /// exit fee percentage
    uint256 public exitFeePercent;

    /// Manager's leveraged earn factor represented as a percentage
    uint16 public managerEarnFactor;

    /// Governance set upper bound for the manager's leveraged earn factor
    uint16 public managerEarnFactorMax;

    /// Part of the managers leverage factor, earnings of witch will be allocated for the manager as protocol earnings.
    /// This value is always equal to (managerEarnFactor - oneHundredPercent)
    uint256 internal managerExcessLeverageComponent;

    /// Percentage of paid interest to be allocated as protocol fee
    uint16 public protocolFeePercent;

    /// An upper bound for percentage of paid interest to be allocated as protocol fee
    uint16 public maxProtocolFeePercent;

    /// Protocol revenues of non-user addresses
    mapping(address => uint256) internal nonUserRevenues;

    /// Weighted average loan APR on the borrowed funds
    uint256 internal weightedAvgStrategyAPR;

    /// Strategy id generator counter
    uint256 private nextStrategyId;

    /// Event for when the lender capital is lost due to defaults
    event UnstakedLoss(uint256 amount);

    /// Event for when the Manager's staked assets are depleted due to defaults
    event StakedAssetsDepleted();

    /**
     * @notice Creates a SaplingPoolContext.
     * @dev Addresses must not be 0.
     * @param _poolToken ERC20 token contract address to be used as the pool issued token.
     * @param _liquidityToken ERC20 token contract address to be used as pool liquidity currency.
     * @param _governance Governance address
     * @param _treasury Treasury wallet address
     * @param _manager Manager address
     */
    function __SaplingPoolContext_init(address _poolToken,
        address _liquidityToken,
        address _governance,
        address _treasury,
        address _manager
    )
        internal
        onlyInitializing
    {
        __SaplingManagerContext_init(_governance, _treasury, _manager);

        /*
            Additional check for single init:
                do not init again if a non-zero value is present in the values yet to be initialized.
        */
        assert(poolToken == address(0) && liquidityToken == address(0));

        require(_poolToken != address(0), "SaplingPoolContext: pool token address is not set");
        require(_liquidityToken != address(0), "SaplingPoolContext: liquidity token address is not set");
        assert(IERC20(_poolToken).totalSupply() == 0);

        poolToken = _poolToken;
        liquidityToken = _liquidityToken;

        tokenBalance = 0;
        stakedShares = 0;

        poolFundsLimit = 0;
        poolFunds = 0;
        poolLiquidity = 0;
        allocatedFunds = 0;
        strategizedFunds = 0;

        targetStakePercent = uint16(10 * 10 ** percentDecimals); //10%
        targetLiquidityPercent = 0; //0%

        exitFeePercent = oneHundredPercent / 200; // 0.5%

        maxProtocolFeePercent = uint16(10 * 10 ** percentDecimals); // 10% by default; safe min 0%, max 10%
        protocolFeePercent = maxProtocolFeePercent;

        managerEarnFactorMax = uint16(1000 * 10 ** percentDecimals); // 1000% or 10x leverage by default
        managerEarnFactor = uint16(150 * 10 ** percentDecimals);
        managerExcessLeverageComponent = uint256(managerEarnFactor).sub(oneHundredPercent);

        uint8 decimals = IERC20Metadata(liquidityToken).decimals();
        tokenDecimals = decimals;
        oneToken = 10 ** decimals;

        weightedAvgStrategyAPR = 0;
        nextStrategyId = 1;
    }

    /**
     * @notice Set the target stake percent for the pool.
     * @dev _targetStakePercent must be inclusively between 0 and oneHundredPercent.
     *      Caller must be the governance.
     * @param _targetStakePercent New target stake percent.
     */
    function setTargetStakePercent(uint16 _targetStakePercent) external onlyGovernance {
        require(0 < _targetStakePercent && _targetStakePercent <= oneHundredPercent,
            "SaplingPoolContext: target stake percent is out of bounds");
        targetStakePercent = _targetStakePercent;
        updatePoolLimit();
    }

    /**
     * @notice Set the target liquidity percent for the pool.
     * @dev _targetLiquidityPercent must be inclusively between 0 and oneHundredPercent.
     *      Caller must be the manager.
     * @param _targetLiquidityPercent new target liquidity percent.
     */
    function setTargetLiquidityPercent(uint16 _targetLiquidityPercent) external onlyManager {
        require(0 <= _targetLiquidityPercent && _targetLiquidityPercent <= oneHundredPercent,
            "SaplingPoolContext: target liquidity percent is out of bounds");
        targetLiquidityPercent = _targetLiquidityPercent;
    }

    /**
     * @notice Set the protocol earning percent for the pool.
     * @dev _protocolEarningPercent must be inclusively between 0 and maxProtocolFeePercent.
     *      Caller must be the governance.
     * @param _protocolEarningPercent new protocol earning percent.
     */
    function setProtocolEarningPercent(uint16 _protocolEarningPercent) external onlyGovernance {
        require(0 <= _protocolEarningPercent && _protocolEarningPercent <= maxProtocolFeePercent,
            "SaplingPoolContext: protocol earning percent is out of bounds");
        protocolFeePercent = _protocolEarningPercent;
    }

    /**
     * @notice Set an upper bound for the manager's earn factor percent.
     * @dev _managerEarnFactorMax must be greater than or equal to oneHundredPercent. If the current earn factor is
     *      greater than the new maximum, then the current earn factor is set to the new maximum.
     *      Caller must be the governance.
     * @param _managerEarnFactorMax new maximum for manager's earn factor.
     */
    function setManagerEarnFactorMax(uint16 _managerEarnFactorMax) external onlyGovernance {
        require(oneHundredPercent <= _managerEarnFactorMax ,
            "SaplingPoolContext: _managerEarnFactorMax is out of bounds");
        managerEarnFactorMax = _managerEarnFactorMax;

        if (managerEarnFactor > managerEarnFactorMax) {
            managerEarnFactor = managerEarnFactorMax;
            managerExcessLeverageComponent = uint256(managerEarnFactor).sub(oneHundredPercent);
        }
    }

    /**
     * @notice Set the manager's earn factor percent.
     * @dev _managerEarnFactorMax must be inclusively between oneHundredPercent and managerEarnFactorMax.
     *      Caller must be the manager.
     * @param _managerEarnFactor new manager's earn factor.
     */
    function setManagerEarnFactor(uint16 _managerEarnFactor) external onlyManager whenNotPaused {
        require(oneHundredPercent <= _managerEarnFactor && _managerEarnFactor <= managerEarnFactorMax,
            "SaplingPoolContext: _managerEarnFactor is out of bounds");
        managerEarnFactor = _managerEarnFactor;
        managerExcessLeverageComponent = uint256(managerEarnFactor).sub(oneHundredPercent);
    }

    /**
     * @notice Deposit liquidity tokens to the pool. Depositing liquidity tokens will mint an equivalent amount of pool
     *         tokens and transfer it to the caller. Exact exchange rate depends on the current pool state.
     * @dev Deposit amount must be non zero and not exceed amountDepositable().
     *      An appropriate spend limit must be present at the token contract.
     *      Caller must not be any of: manager, protocol, governance.
     * @param amount Liquidity token amount to deposit.
     */
    function deposit(uint256 amount) external onlyUser whenNotPaused whenNotClosed {
        enterPool(amount);
    }

    /**
     * @notice Withdraw liquidity tokens from the pool. Withdrawals redeem equivalent amount of the caller's pool tokens
     *         by burning the tokens in question.
     *         Exact exchange rate depends on the current pool state.
     * @dev Withdrawal amount must be non zero and not exceed amountWithdrawable().
     * @param amount Liquidity token amount to withdraw.
     */
    function withdraw(uint256 amount) external whenNotPaused {
        require(msg.sender != manager, "SaplingPoolContext: pool manager address cannot use withdraw");

        exitPool(amount);
    }

    /**
     * @notice Stake liquidity tokens into the pool. Staking liquidity tokens will mint an equivalent amount of pool
     *         tokens and lock them in the pool. Exact exchange rate depends on the current pool state.
     * @dev Caller must be the manager.
     *      Stake amount must be non zero.
     *      An appropriate spend limit must be present at the token contract.
     * @param amount Liquidity token amount to stake.
     */
    function stake(uint256 amount) external onlyManager whenNotPaused whenNotClosed {
        require(amount > 0, "SaplingPoolContext: stake amount is 0");

        uint256 shares = enterPool(amount);
        stakedShares = stakedShares.add(shares);
        updatePoolLimit();
    }

    /**
     * @notice Unstake liquidity tokens from the pool. Unstaking redeems equivalent amount of the caller's pool tokens
     *         locked in the pool by burning the tokens in question.
     * @dev Caller must be the manager.
     *      Unstake amount must be non zero and not exceed amountUnstakable().
     * @param amount Liquidity token amount to unstake.
     */
    function unstake(uint256 amount) external onlyManager whenNotPaused {
        require(amount > 0, "SaplingPoolContext: unstake amount is 0");
        require(amount <= amountUnstakable(), "SaplingPoolContext: requested amount is not available for unstaking");

        exitPool(amount);
    }

    /**
     * @notice Withdraws protocol revenue belonging to the caller.
     * @dev revenueBalanceOf(msg.sender) must be greater than 0.
     *      Caller's all accumulated earnings will be withdrawn.
     *      Protocol earnings are represented in liquidity tokens.
     */
    function withdrawRevenue() external whenNotPaused {
        require(nonUserRevenues[msg.sender] > 0, "SaplingPoolContext: zero protocol earnings");
        uint256 amount = nonUserRevenues[msg.sender];
        nonUserRevenues[msg.sender] = 0;

        // give tokens
        tokenBalance = tokenBalance.sub(amount);
        bool success = IERC20(liquidityToken).transfer(msg.sender, amount);
        require(success, "SaplingPoolContext: ERC20 transfer failed");
    }

    /**
     * @notice Check liquidity token amount depositable by lenders at this time.
     * @dev Return value depends on the pool state rather than caller's balance.
     * @return Max amount of tokens depositable to the pool.
     */
    function amountDepositable() external view returns (uint256) {
        if (poolFundsLimit <= poolFunds || closed() || paused()) {
            return 0;
        }

        return poolFundsLimit.sub(poolFunds);
    }

    /**
     * @notice Check liquidity token amount withdrawable by the caller at this time.
     * @dev Return value depends on the callers balance, and is limited by pool liquidity.
     * @param wallet Address of the wallet to check the withdrawable balance of.
     * @return Max amount of tokens withdrawable by the caller.
     */
    function amountWithdrawable(address wallet) external view returns (uint256) {
        return paused() ? 0 : MathUpgradeable.min(poolLiquidity, balanceOf(wallet));
    }

    /**
     * @notice Check the manager's staked liquidity token balance in the pool.
     * @return Liquidity token balance of the manager's stake.
     */
    function balanceStaked() external view returns (uint256) {
        return sharesToTokens(stakedShares);
    }

    /**
     * @notice Check the special addresses' revenue from the protocol.
     * @dev This method is useful for manager and protocol addresses.
     *      Calling this method for a non-protocol associated addresses will return 0.
     * @param wallet Address of the wallet to check the earnings balance of.
     * @return Accumulated liquidity token revenue of the wallet from the protocol.
     */
    function revenueBalanceOf(address wallet) external view returns (uint256) {
        return nonUserRevenues[wallet];
    }

    /**
     * @notice Estimated lender APY given the current pool state.
     * @return Estimated current lender APY
     */
    function currentLenderAPY() external view returns (uint16) {
        return lenderAPY(strategizedFunds, weightedAvgStrategyAPR);
    }

    /**
     * @notice Projected lender APY given the current pool state and a specific strategy rate and an average apr.
     * @dev Represent percentage parameter values in contract specific format.
     * @param strategyRate Percentage of pool funds projected to be used in strategies.
     * @return Projected lender APY
     */
    function projectedLenderAPY(uint16 strategyRate, uint256 _avgStrategyAPR) external view returns (uint16) {
        require(strategyRate <= oneHundredPercent, "SaplingPoolContext: invalid borrow rate");
        return lenderAPY(MathUpgradeable.mulDiv(poolFunds, strategyRate, oneHundredPercent), _avgStrategyAPR);
    }

    /**
     * @notice Check wallet's liquidity token balance in the pool. This balance includes deposited balance and acquired
     *         yield. This balance does not included staked balance, leveraged revenue or protocol revenue.
     * @param wallet Address of the wallet to check the balance of.
     * @return Liquidity token balance of the wallet in this pool.
     */
    function balanceOf(address wallet) public view returns (uint256) {
        return sharesToTokens(IPoolToken(poolToken).balanceOf(wallet));
    }

    /**
     * @notice Check liquidity token amount unstakable by the manager at this time.
     * @dev Return value depends on the manager's stake balance and targetStakePercent, and is limited by pool
     *      liquidity.
     * @return Max amount of tokens unstakable by the manager.
     */
    function amountUnstakable() public view returns (uint256) {
        uint256 totalPoolShares = IERC20(poolToken).totalSupply();
        if (paused() || targetStakePercent >= oneHundredPercent && totalPoolShares > stakedShares) {
            return 0;
        } else if (closed() || totalPoolShares == stakedShares) {
            return MathUpgradeable.min(poolLiquidity, sharesToTokens(stakedShares));
        }

        uint256 lenderShares = totalPoolShares.sub(stakedShares);
        uint256 lockedStakeShares = MathUpgradeable.mulDiv(
            lenderShares,
            targetStakePercent,
            oneHundredPercent - targetStakePercent
        );

        return MathUpgradeable.min(poolLiquidity, sharesToTokens(stakedShares.sub(lockedStakeShares)));
    }

    /**
     * @notice Current liquidity available for pool strategies such as lending or investing.
     * @return Strategy liquidity amount.
     */
    function strategyLiquidity() public view returns (uint256) {
        uint256 lenderAllocatedLiquidity = MathUpgradeable.mulDiv(poolFunds, targetLiquidityPercent, oneHundredPercent);

        if (poolLiquidity <= lenderAllocatedLiquidity) {
            return 0;
        }

        return poolLiquidity.sub(lenderAllocatedLiquidity);
    }

    /**
     * @dev Generator for next strategy id. i.e. loan, investment.
     * @return Next available id.
     */
    function getNextStrategyId() internal nonReentrant returns (uint256) {
        uint256 id = nextStrategyId;
        nextStrategyId++;
        return id;
    }

    /**
     * @dev Internal method to enter the pool with a liquidity token amount.
     *      With the exception of the manager's call, amount must not exceed amountDepositable().
     *      If the caller is the pool manager, entered funds are considered staked.
     *      New pool tokens are minted in a way that will not influence the current share price.
     * @dev Shares are equivalent to pool tokens and are represented by them.
     * @param amount Liquidity token amount to add to the pool on behalf of the caller.
     * @return Amount of pool tokens minted and allocated to the caller.
     */
    function enterPool(uint256 amount) internal nonReentrant returns (uint256) {
        require(amount > 0, "SaplingPoolContext: pool deposit amount is 0");

        // allow the manager to add funds beyond the current pool limit
        require(msg.sender == manager || (poolFundsLimit > poolFunds && amount <= poolFundsLimit.sub(poolFunds)),
            "SaplingPoolContext: deposit amount is over the remaining pool limit");

        uint256 shares = tokensToShares(amount);

        // charge 'amount' tokens from msg.sender
        bool success = IERC20(liquidityToken).transferFrom(msg.sender, address(this), amount);
        require(success, "SaplingPoolContext: ERC20 transfer failed");
        tokenBalance = tokenBalance.add(amount);

        poolLiquidity = poolLiquidity.add(amount);
        poolFunds = poolFunds.add(amount);

        // mint shares
        IPoolToken(poolToken).mint(msg.sender != manager ? msg.sender : address(this), shares);

        return shares;
    }

    /**
     * @dev Internal method to exit the pool with a liquidity token amount.
     *      Amount must not exceed amountWithdrawable() for non managers, and amountUnstakable() for the manager.
     *      If the caller is the pool manager, exited funds are considered unstaked.
     *      Pool tokens are burned in a way that will not influence the current share price.
     * @dev Shares are equivalent to pool tokens and are represented by them.
     * @param amount Liquidity token amount to withdraw from the pool on behalf of the caller.
     * @return Amount of pool tokens burned and taken from the caller.
     */
    function exitPool(uint256 amount) internal returns (uint256) {
        require(amount > 0, "SaplingPoolContext: pool withdrawal amount is 0");
        require(poolLiquidity >= amount, "SaplingPoolContext: insufficient liquidity");

        uint256 shares = tokensToShares(amount);

        require(msg.sender != manager ? shares <= IERC20(poolToken).balanceOf(msg.sender) : shares <= stakedShares,
            "SaplingPoolContext: insufficient balance");

        if (msg.sender == manager) {
            stakedShares = stakedShares.sub(shares);
            updatePoolLimit();
        }

        // burn shares
        IPoolToken(poolToken).burn(msg.sender != manager ? msg.sender : address(this), shares);

        uint256 transferAmount = amount.sub(MathUpgradeable.mulDiv(amount, exitFeePercent, oneHundredPercent));

        poolFunds = poolFunds.sub(transferAmount);
        poolLiquidity = poolLiquidity.sub(transferAmount);

        tokenBalance = tokenBalance.sub(transferAmount);
        bool success = IERC20(liquidityToken).transfer(msg.sender, transferAmount);
        require(success, "SaplingPoolContext: ERC20 transfer failed");

        return shares;
    }

    /**
     * @dev Internal method to update the pool funds limit based on the staked funds.
     */
    function updatePoolLimit() internal {
        poolFundsLimit = sharesToTokens(MathUpgradeable.mulDiv(stakedShares, oneHundredPercent, targetStakePercent));
    }

    /**
     * @dev Internal method to update the weighted average loan apr based on the amount reduced by and an apr.
     * @param amountReducedBy amount by which the funds committed into strategy were reduced, due to repayment or loss
     * @param apr annual percentage rate of the strategy
     */
    function updateAvgStrategyApr(uint256 amountReducedBy, uint16 apr) internal {
        if (strategizedFunds > 0) {
            weightedAvgStrategyAPR = strategizedFunds
                .add(amountReducedBy)
                .mul(weightedAvgStrategyAPR)
                .sub(amountReducedBy.mul(apr))
                .div(strategizedFunds);
        } else {
            weightedAvgStrategyAPR = 0;
        }
    }

    /**
     * @notice Get liquidity token value of shares.
     * @dev Shares are equivalent to pool tokens and are represented by them.
     * @param shares Amount of shares
     */
    function sharesToTokens(uint256 shares) internal view returns (uint256) {
        if (shares == 0 || poolFunds == 0) {
             return 0;
        }

        return MathUpgradeable.mulDiv(shares, poolFunds, IERC20(poolToken).totalSupply());
    }

    /**
     * @notice Get a share value of liquidity tokens.
     * @dev Shares are equivalent to pool tokens and are represented by them.
     * @param tokens Amount of liquidity tokens.
     */
    function tokensToShares(uint256 tokens) internal view returns (uint256) {
        uint256 totalPoolShares = IERC20(poolToken).totalSupply();

        if (totalPoolShares == 0) {
            // a pool with no positions
            return tokens;
        } else if (poolFunds == 0) {
            /*
                Handle failed pool case, where: poolFunds == 0, but totalPoolShares > 0
                To minimize loss for the new depositor, assume the total value of existing shares is the minimum
                possible nonzero integer, which is 1.

                Simplify (tokens * totalPoolShares) / 1 as tokens * totalPoolShares.
            */
            return tokens.mul(totalPoolShares);
        }

        return MathUpgradeable.mulDiv(tokens, totalPoolShares, poolFunds);
    }

    /**
     * @dev All time count of created strategies. i.e. Loans and investments
     */
    function strategyCount() internal view returns(uint256) {
        return nextStrategyId - 1;
    }

    /**
     * @notice Lender APY given the current pool state, a specific strategized funds, and an average apr.
     * @dev Represent percentage parameter values in contract specific format.
     * @param _strategizedFunds Pool funds to be borrowed annually.
     * @return Lender APY
     */
    function lenderAPY(uint256 _strategizedFunds, uint256 _avgStrategyAPR) internal view returns (uint16) {
        if (poolFunds == 0 || _strategizedFunds == 0 || _avgStrategyAPR == 0) {
            return 0;
        }

        // pool APY
        uint256 poolAPY = MathUpgradeable.mulDiv(_avgStrategyAPR, _strategizedFunds, poolFunds);

        // protocol APY
        uint256 protocolAPY = MathUpgradeable.mulDiv(poolAPY, protocolFeePercent, oneHundredPercent);

        uint256 remainingAPY = poolAPY.sub(protocolAPY);

        // manager withdrawableAPY
        uint256 currentStakePercent = MathUpgradeable.mulDiv(
            stakedShares,
            oneHundredPercent,
            IERC20(poolToken).totalSupply()
        );
        uint256 managerEarningsPercent = MathUpgradeable.mulDiv(
            currentStakePercent,
            managerExcessLeverageComponent,
            oneHundredPercent);

        uint256 managerWithdrawableAPY = MathUpgradeable.mulDiv(
            remainingAPY,
            managerEarningsPercent,
            managerEarningsPercent + oneHundredPercent
        );

        return uint16(remainingAPY.sub(managerWithdrawableAPY));
    }

    /**
     * @notice Check if the pool is functional based on the current stake levels.
     * @return True if the staked funds provide at least a minimum ratio to the pool funds, False otherwise.
     */
    function isPoolFunctional() internal view returns (bool) {
        return !(paused() || closed())
            && stakedShares >= MathUpgradeable.mulDiv(
                IERC20(poolToken).totalSupply(),
                targetStakePercent,
                oneHundredPercent
            );
    }


    /**
     * @dev Implementation of the abstract hook in SaplingManagedContext.
     *      Governance, protocol wallet addresses are authorised to take
     *      certain actions when the manager is inactive.
     */
    function authorizedOnInactiveManager(address caller) internal view override returns (bool) {
        return isNonUserAddress(caller);
    }

    /**
     * @dev Implementation of the abstract hook in SaplingManagedContext.
     *      Pool can be close when no funds remain committed to strategies.
     */
    function canClose() internal view override returns (bool) {
        return strategizedFunds == 0;
    }
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
     * the logical initial state.
     */
    enum LoanApplicationStatus {
        NULL,
        APPLIED,
        DENIED,
        OFFER_MADE,
        OFFER_ACCEPTED,
        OFFER_CANCELLED
    }

    /// Loan offer object template
    struct LoanOffer {
        uint256 applicationId; // ID of the loan application this offer is made for
        address borrower; // applicant address
        uint256 amount; // offered loan principal amount in liquidity tokens
        uint256 duration; // requested loan term in seconds
        uint256 gracePeriod; // payment grace period in seconds
        uint256 installmentAmount; // minimum payment amount on each instalment in liquidity tokens
        uint16 installments; //number of payment installments
        uint16 apr; // annual percentage rate of this loan
        uint256 offeredTime; //the time this offer was created or last updated
    }

    /**
     * @dev Hook to be called when a loan offer is accepted.
     * @param appId ID of the application the accepted offer was made for.
     */
    function onBorrow(uint256 appId) external;

    /**
     * @notice Accessor for application status.
     * @dev NULL status is returned for nonexistent applications.
     * @param appId ID of the application in question.
     * @return Current status of the application with the specified ID.
     */
    function applicationStatus(uint256 appId) external view returns (LoanApplicationStatus);

    /**
     * @notice Accessor for loan offer.
     * @dev Loan offer is valid when the loan application is present and has OFFER_MADE status.
     * @param appId ID of the application the offer was made for.
     * @return LoanOffer struct instance for the specified application ID.
     */
    function loanOfferById(uint256 appId) external view returns (LoanOffer memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
 * @title LoanDesk Owner Interface
 * @dev Interface defining functional hooks for LoanDesk, and setup hooks for SaplingFactory.
 */
interface ILoanDeskOwner {

    /**
     * @notice Links a new loan desk for the pool to use. Intended for use upon initial pool deployment.
     * @dev Caller must be the governance.
     * @param _loanDesk New LoanDesk address
     */
    function setLoanDesk(address _loanDesk) external;

    /**
     * @notice Handles liquidity state changes on a loan offer.
     * @dev Hook to be called when a new loan offer is made.
     *      Caller must be the LoanDesk.
     * @param amount Loan offer amount.
     */
    function onOffer(uint256 amount) external;

    /**
     * @dev Hook to be called when a loan offer amount is updated. Amount update can be due to offer update or
     *      cancellation. Caller must be the LoanDesk.
     * @param prevAmount The original, now previous, offer amount.
     * @param amount New offer amount. Cancelled offer must register an amount of 0 (zero).
     */
    function onOfferUpdate(uint256 prevAmount, uint256 amount) external;

    /**
     * @dev Hook for checking if the lending pool can provide liquidity for the total offered loans amount.
     * @param totalOfferedAmount Total sum of offered loan amount including outstanding offers
     * @return True if the pool has sufficient lending liquidity, false otherwise.
     */
    function canOffer(uint256 totalOfferedAmount) external view returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title PoolToken Interface
 * @notice Defines the hooks for the lending pool.
 */
interface IPoolToken is IERC20 {

    /**
     * @notice Mint tokens.
     * @dev Hook for the lending pool for mining tokens upon pool entry operations.
     *      Caller must be the lending pool that owns this token.
     * @param to Address the tokens are minted for
     * @param amount The amount of tokens to mint
     */
    function mint(address to, uint256 amount) external;

    /**
     * @notice Burn tokens.
     * @dev Hook for the lending pool for burning tokens upon pool exit or stake loss operations.
     *      Caller must be the lending pool that owns this token.
     * @param from Address the tokens are burned from
     * @param amount The amount of tokens to burn
     */
    function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "./SaplingContext.sol";

/**
 * @title Sapling Manager Context
 * @notice Provides manager access control, and a basic close functionality.
 */
abstract contract SaplingManagerContext is SaplingContext {

    /// Manager address
    address public manager;

    /// Flag indicating whether or not the pool is closed
    bool private _closed;

    // Common math context used in all protocol components that extend this contract
    /// Number of decimal digits in integer percent values used across the contract
    uint16 public percentDecimals;

    /// A constant representing 100%
    uint16 public oneHundredPercent;

    /**
     * @notice Grace period for the manager to be inactive on a given loan /cancel/default decision.
     *         After this grace period of managers inaction on a given loan authorized parties
     *         can also call cancel() and default(). Other requirements for loan cancellation/default still apply.
     */
    uint256 public constant MANAGER_INACTIVITY_GRACE_PERIOD = 90 days;

    /// Event for when the contract is closed
    event Closed(address account);

    /// Event for when the contract is reopened
    event Opened(address account);

    /// Event for when a new manager is set
    event ManagerTransferred(address from, address to);

    /// A modifier to limit access only to the manager
    modifier onlyManager {
        require(msg.sender == manager, "SaplingManagerContext: caller is not the manager");
        _;
    }

    /// A modifier to limit access to the manager or to other applicable parties when the manager is considered inactive
    modifier managerOrApprovedOnInactive {
        require(msg.sender == manager || authorizedOnInactiveManager(msg.sender),
            "SaplingManagerContext: caller is neither the manager nor an approved party");
        _;
    }

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
     * @param _governance Governance address
     * @param _treasury Treasury wallet address
     * @param _manager Manager address
     */
    function __SaplingManagerContext_init(
        address _governance,
        address _treasury,
        address _manager
    )
        internal
        onlyInitializing
    {
        __SaplingContext_init(_governance, _treasury);

        /*
            Additional check for single init:
                do not init again if a non-zero value is present in the values yet to be initialized.
        */
        assert(manager == address(0) && _closed == false && percentDecimals == 0 && oneHundredPercent == 0);

        require(_manager != address(0), "SaplingManagerContext: manager address is not set");
        manager = _manager;
        _closed = false;

        //init math context state
        percentDecimals = 1;
        oneHundredPercent = uint16(100 * 10 ** percentDecimals);
    }

    /**
     * @notice Transfer the manager.
     * @dev Caller must be the governance.
     *      New manager address must not be 0, and must not be one of current non-user addresses.
     * @param _manager New manager address
     */
    function transferManager(address _manager) external onlyGovernance {
        require(
            _manager != address(0) && !isNonUserAddress(_manager),
            "SaplingManagerContext: invalid manager address"
        );
        address prevManager = manager;
        manager = _manager;
        emit ManagerTransferred(prevManager, manager);
    }

    /**
     * @notice Close the pool and stop borrowing, lender deposits, and staking.
     * @dev Caller must be the manager.
     *      Pool must be open.
     *      No loans or approvals must be outstanding (borrowedFunds must equal to 0).
     *      Emits 'PoolClosed' event.
     */
    function close() external onlyManager whenNotClosed {
        require(canClose(), "SaplingManagerContext: cannot close the pool with outstanding loans");
        _closed = true;
        emit Closed(msg.sender);
    }

    /**
     * @notice Open the pool for normal operations.
     * @dev Caller must be the manager.
     *      Pool must be closed.
     *      Opening the pool will not unpause any pauses in effect.
     *      Emits 'PoolOpened' event.
     */
    function open() external onlyManager whenClosed {
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
     * @notice Verify if an address is currently in any non-user/management position.
     * @dev a hook in Sampling Context
     * @param party Address to verify
     */
    function isNonUserAddress(address party) internal view override returns (bool) {
        return party == manager || super.isNonUserAddress(party);
    }
    /**
     * @notice Indicates whether or not the contract can be closed in it's current state.
     * @dev A hook for the extending contract to implement.
     * @return True if the contract is closed, false otherwise.
     */
    function canClose() internal view virtual returns (bool);

    /**
     * @notice Indicates whether or not the the caller is authorized to take applicable managing actions when the
     *         manager is inactive.
     * @dev A hook for the extending contract to implement.
     * @param caller Caller's address.
     * @return True if the caller is authorized at this time, false otherwise.
     */
    function authorizedOnInactiveManager(address caller) internal view virtual returns (bool);
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
library SafeMathUpgradeable {
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

pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

/**
 * @title Sapling Context
 * @notice Provides governance access control, a common reverence to the treasury wallet address, and basic pause
 *         functionality by extending OpenZeppelin's Pausable contract.
 */
abstract contract SaplingContext is Initializable, PausableUpgradeable {

    /// Protocol governance
    address public governance;

    /// Protocol treasury wallet address
    address public treasury;

    /// Event for when a new governance is set
    event GovernanceTransferred(address from, address to);

    /// Event for when a new treasury wallet is set
    event TreasuryWalletTransferred(address from, address to);

    /// A modifier to limit access only to the governance
    modifier onlyGovernance {
        require(msg.sender == governance, "SaplingContext: caller is not the governance");
        _;
    }

    /**
     * @notice Creates a new SaplingContext.
     * @dev Addresses must not be 0.
     * @param _governance Governance address
     * @param _treasury Treasury wallet address
     */
    function __SaplingContext_init(address _governance, address _treasury) internal onlyInitializing {
        __Pausable_init();

        /*
            Additional check for single init:
                do not init again if a non-zero value is present in the values yet to be initialized.
        */
        assert(governance == address(0) && treasury == address(0));

        require(_governance != address(0), "SaplingContext: governance address is not set");
        require(_treasury != address(0), "SaplingContext: treasury wallet address is not set");
        governance = _governance;
        treasury = _treasury;
    }

    /**
     * @notice Pause the contract.
     * @dev Caller must be the governance.
     *      Only the functions using whenPaused and whenNotPaused modifiers will be affected by pause.
     */
    function pause() external onlyGovernance {
        _pause();
    }

    /**
     * @notice Resume the contract.
     * @dev Caller must be the governance.
     *      Only the functions using whenPaused and whenNotPaused modifiers will be affected by unpause.
     */
    function unpause() external onlyGovernance {
        _unpause();
    }

    /**
     * @notice Transfer the governance.
     * @dev Caller must be the governance.
     *      New governance address must not be 0, and must not be one of current non-user addresses.
     * @param _governance New governance address.
     */
    function transferGovernance(address _governance) external onlyGovernance {
        require(
            _governance != address(0) && !isNonUserAddress(_governance),
            "SaplingContext: invalid governance address"
        );
        address prevGovernance = governance;
        governance = _governance;
        emit GovernanceTransferred(prevGovernance, governance);
    }

    /**
     * @notice Transfer the treasury role.
     * @dev Caller must be the governance.
     *      New treasury address must not be 0, and must not be one of current non-user addresses.
     * @param _treasury New treasury wallet address
     */
    function transferTreasury(address _treasury) external onlyGovernance {
        require(
            _treasury != address(0) && !isNonUserAddress(_treasury),
            "SaplingContext: invalid treasury wallet address"
        );
        address prevTreasury = treasury;
        treasury = _treasury;
        emit TreasuryWalletTransferred(prevTreasury, treasury);
        afterTreasuryWalletTransfer(prevTreasury);
    }

    /**
     * @notice Hook that is called after a new treasury wallet address has been set.
     * @param from Address of the previous treasury wallet.
     */
    function afterTreasuryWalletTransfer(address from) internal virtual {}

    /**
     * @notice Hook that is called to verify if an address is currently in any non-user/management position.
     * @dev When overriding, return "contract local verification result" AND super.isNonUserAddress(party).
     * @param party Address to verify
     */
    function isNonUserAddress(address party) internal view virtual returns (bool) {
        return party == governance || party == treasury;
    }
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