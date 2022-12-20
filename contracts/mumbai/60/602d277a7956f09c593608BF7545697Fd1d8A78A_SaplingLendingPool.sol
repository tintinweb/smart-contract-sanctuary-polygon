// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./context/SaplingPoolContext.sol";
import "./interfaces/ILendingPool.sol";
import "./interfaces/ILoanDesk.sol";

/**
 * @title Sapling Lending Pool
 * @dev Extends SaplingPoolContext with lending strategy.
 */
contract SaplingLendingPool is ILendingPool, SaplingPoolContext {

    /// Address of the loan desk contract
    address public loanDesk;

    /// Mark loan funds released flags to guards against double withdrawals due to future bugs or compromised LoanDesk
    mapping(address => mapping(uint256 => bool)) private loanFundsReleased;

    /// Mark the loans closed to guards against double actions due to future bugs or compromised LoanDesk
    mapping(address => mapping(uint256 => bool)) private loanClosed;

    /// A modifier to limit access only to the loan desk contract
    modifier onlyLoanDesk() {
        require(msg.sender == loanDesk, "SaplingLendingPool: caller is not the LoanDesk");
        _;
    }

    /**
     * @dev Disable initializers
     */
    function disableIntitializers() external onlyRole(SaplingRoles.GOVERNANCE_ROLE) {
        _disableInitializers();
    }

    /**
     * @notice Creates a Sapling pool.
     * @dev Addresses must not be 0.
     * @param _poolToken ERC20 token contract address to be used as the pool issued token.
     * @param _liquidityToken ERC20 token contract address to be used as pool liquidity currency.
     * @param _accessControl Access control contract
     * @param _managerRole Manager role
     */
    function initialize(
        address _poolToken,
        address _liquidityToken,
        address _accessControl,
        bytes32 _managerRole
    )
        public
        initializer
    {
        __SaplingPoolContext_init(_poolToken, _liquidityToken, _accessControl, _managerRole);
    }

    /**
     * @notice Links a new loan desk for the pool to use. Intended for use upon initial pool deployment.
     * @dev Caller must be the governance.
     * @param _loanDesk New LoanDesk address
     */
    function setLoanDesk(address _loanDesk) external onlyRole(SaplingRoles.GOVERNANCE_ROLE) {
        address prevLoanDesk = loanDesk;
        loanDesk = _loanDesk;
        emit LoanDeskSet(prevLoanDesk, loanDesk);
    }

    /**
     * @dev Hook for a new loan offer. Caller must be the LoanDesk.
     * @param amount Loan offer amount.
     */
    function onOffer(uint256 amount) external onlyLoanDesk whenNotPaused whenNotClosed {
        require(strategyLiquidity() >= amount, "SaplingLendingPool: insufficient liquidity");

        balances.rawLiquidity -= amount;
        balances.allocatedFunds += amount;

        emit OfferLiquidityAllocated(amount);
    }

    /**
     * @dev Hook for a loan offer amount update. Amount update can be due to offer update or
     *      cancellation. Caller must be the LoanDesk.
     * @param prevAmount The original, now previous, offer amount.
     * @param amount New offer amount. Cancelled offer must register an amount of 0 (zero).
     */
    function onOfferUpdate(uint256 prevAmount, uint256 amount) external onlyLoanDesk whenNotPaused whenNotClosed {
        require(strategyLiquidity() + prevAmount >= amount, "SaplingLendingPool: insufficient liquidity");

        balances.rawLiquidity = balances.rawLiquidity + prevAmount - amount;
        balances.allocatedFunds = balances.allocatedFunds - prevAmount + amount;

        emit OfferLiquidityUpdated(prevAmount, amount);
    }

    /**
     * @dev Hook for borrow. Releases the loan funds to the borrower. Caller must be the LoanDesk. 
     * Loan metadata is passed along as call arguments to avoid reentry callbacks to the LoanDesk.
     * @param loanId ID of the loan which has just been borrowed
     * @param borrower Address of the borrower
     * @param amount Loan principal amount
     * @param apr Loan apr
     */
    function onBorrow(
        uint256 loanId, 
        address borrower, 
        uint256 amount, 
        uint16 apr
    ) 
        external 
        onlyLoanDesk
        nonReentrant
        whenNotPaused
        whenNotClosed
    {
        // check
        require(loanFundsReleased[loanDesk][loanId] == false, "SaplingLendingPool: loan funds already released");

        // @dev trust the loan validity via LoanDesk checks as the only authorized caller is LoanDesk

        //// effect

        loanFundsReleased[loanDesk][loanId] = true;
        
        uint256 prevStrategizedFunds = balances.strategizedFunds;
        
        balances.tokenBalance -= amount;
        balances.allocatedFunds -= amount;
        balances.strategizedFunds += amount;

        config.weightedAvgStrategyAPR = (prevStrategizedFunds * config.weightedAvgStrategyAPR + amount * apr)
            / balances.strategizedFunds;

        //// interactions

        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(tokenConfig.liquidityToken), borrower, amount);

        emit LoanFundsReleased(loanId, borrower, amount);
    }

     /**
     * @dev Hook for repayments. Caller must be the LoanDesk. 
     *      
     *      Parameters besides the loanId exists simply to avoid rereading it from the caller via additinal inter 
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
    ) 
        external 
        onlyLoanDesk
        nonReentrant
        whenNotPaused
        whenNotClosed
    {
        //// check
        require(loanFundsReleased[loanDesk][loanId] == true, "SaplingLendingPool: loan is not borrowed");
        require(loanClosed[loanDesk][loanId] == false, "SaplingLendingPool: loan is closed");

        // @dev trust the loan validity via LoanDesk checks as the only caller authorized is LoanDesk

        //// effect

        balances.tokenBalance += transferAmount;

        uint256 principalPaid;
        if (interestPayable == 0) {
            principalPaid = paymentAmount;
            balances.rawLiquidity += paymentAmount;
        } else {
            principalPaid = paymentAmount - interestPayable;

            //share revenue to treasury
            uint256 protocolEarnedInterest = MathUpgradeable.mulDiv(
                interestPayable,
                config.protocolFeePercent,
                SaplingMath.HUNDRED_PERCENT
            );

            balances.protocolRevenue += protocolEarnedInterest;

            //share revenue to manager
            uint256 currentStakePercent = MathUpgradeable.mulDiv(
                balances.stakedShares,
                SaplingMath.HUNDRED_PERCENT,
                totalPoolTokenSupply()
            );

            uint256 managerEarningsPercent = MathUpgradeable.mulDiv(
                currentStakePercent,
                config.managerEarnFactor - SaplingMath.HUNDRED_PERCENT,
                SaplingMath.HUNDRED_PERCENT
            );

            uint256 managerEarnedInterest = MathUpgradeable.mulDiv(
                interestPayable - protocolEarnedInterest,
                managerEarningsPercent,
                managerEarningsPercent + SaplingMath.HUNDRED_PERCENT
            );

            balances.managerRevenue += managerEarnedInterest;

            balances.rawLiquidity += paymentAmount - (protocolEarnedInterest + managerEarnedInterest);
            balances.poolFunds += interestPayable - (protocolEarnedInterest + managerEarnedInterest);
        }

        balances.strategizedFunds -= principalPaid;

        updateAvgStrategyApr(principalPaid, apr);

        //// interactions

        // charge 'amount' tokens from msg.sender
        SafeERC20Upgradeable.safeTransferFrom(
            IERC20Upgradeable(tokenConfig.liquidityToken),
            payer,
            address(this),
            transferAmount
        );

        emit LoanRepaymentConfirmed(loanId, borrower, payer, transferAmount, interestPayable);
    }

    /**
     * @dev Hook for closing a loan. Caller must be the LoanDesk. Closing a loan will repay the outstanding principal 
     * using the pool manager's revenue and/or staked funds. If these funds are not sufficient, the lenders will 
     * share the loss.
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
        onlyLoanDesk
        nonReentrant
        whenNotPaused
        whenNotClosed
        returns (uint256)
    {
        //// check
        require(loanClosed[loanDesk][loanId] == false, "SaplingLendingPool: loan is closed");

        // @dev trust the loan validity via LoanDesk checks as the only caller authorized is LoanDesk

        //// effect

        loanClosed[loanDesk][loanId] == true;

        // charge manager's revenue
        if (remainingDifference > 0 && balances.managerRevenue > 0) {
            uint256 amountChargeable = MathUpgradeable.min(remainingDifference, balances.managerRevenue);

            balances.managerRevenue -= amountChargeable;

            remainingDifference -= amountChargeable;
            amountRepaid += amountChargeable;
        }

        // charge manager's stake
        uint256 stakeChargeable = 0;
        if (remainingDifference > 0 && balances.stakedShares > 0) {
            uint256 stakedBalance = tokensToFunds(balances.stakedShares);
            uint256 amountChargeable = MathUpgradeable.min(remainingDifference, stakedBalance);
            stakeChargeable = fundsToTokens(amountChargeable);

            balances.stakedShares = balances.stakedShares - stakeChargeable;

            if (balances.stakedShares == 0) {
                emit StakedAssetsDepleted();
            }

            remainingDifference -= amountChargeable;
            amountRepaid += amountChargeable;
        }

        if (amountRepaid > 0) {
            balances.strategizedFunds -= amountRepaid;
            balances.rawLiquidity += amountRepaid;
        }

        // charge pool (close loan and reduce borrowed funds/poolfunds)
        if (remainingDifference > 0) {
            balances.strategizedFunds -= remainingDifference;
            balances.poolFunds -= remainingDifference;

            emit UnstakedLoss(remainingDifference);
        }

        updateAvgStrategyApr(amountRepaid + remainingDifference, apr);

        //// interactions
        if (stakeChargeable > 0) {
            IPoolToken(tokenConfig.poolToken).burn(address(this), stakeChargeable);
        }

        return amountRepaid;
    }

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
        onlyLoanDesk
        nonReentrant
        whenNotPaused
        whenNotClosed
        returns (uint256, uint256)
    {
        //// check
        require(loanClosed[loanDesk][loanId] == false, "SaplingLendingPool: loan is closed");

        // @dev trust the loan validity via LoanDesk checks as the only caller authorized is LoanDesk

        //// effect
        loanClosed[loanDesk][loanId] == true;

        if (carryAmountUsed > 0) {
            balances.strategizedFunds -= carryAmountUsed;
            balances.rawLiquidity += carryAmountUsed;
        }

        uint256 managerLoss = loss;
        uint256 lenderLoss = 0;

        if (loss > 0) {
            uint256 remainingLostShares = fundsToTokens(loss);

            balances.poolFunds -= loss;
            balances.strategizedFunds -= loss;
            updateAvgStrategyApr(loss, apr);

            if (balances.stakedShares > 0) {
                uint256 stakedShareLoss = MathUpgradeable.min(remainingLostShares, balances.stakedShares);
                remainingLostShares -= stakedShareLoss;
                balances.stakedShares -= stakedShareLoss;

                if (balances.stakedShares == 0) {
                    emit StakedAssetsDepleted();
                }

                //// interactions

                //burn manager's shares; this external interaction must happen before calculating lender loss
                IPoolToken(tokenConfig.poolToken).burn(address(this), stakedShareLoss);
            }

            if (remainingLostShares > 0) {
                lenderLoss = tokensToFunds(remainingLostShares);
                managerLoss -= lenderLoss;

                emit UnstakedLoss(lenderLoss);
            }
        }

        return (managerLoss, lenderLoss);
    }

    /**
     * @notice View indicating whether or not a given loan can be offered by the manager.
     * @dev Hook for checking if the lending pool can provide liquidity for the total offered loans amount.
     * @param totalOfferedAmount Total sum of offered loan amount including outstanding offers
     * @return True if the pool has sufficient lending liquidity, false otherwise
     */
    function canOffer(uint256 totalOfferedAmount) external view returns (bool) {
        return !paused() 
            && !closed() 
            && maintainsStakeRatio()
            && totalOfferedAmount <= strategyLiquidity() + balances.allocatedFunds;
    }

    /**
     * @notice Indicates whether or not the contract can be opened in it's current state.
     * @dev Overrides a hook in SaplingManagerContext.
     * @return True if the conditions to open are met, false otherwise.
     */
    function canOpen() internal view override returns (bool) {
        return loanDesk != address(0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../interfaces/IPoolContext.sol";
import "../interfaces/IPoolToken.sol";
import "./SaplingManagerContext.sol";
import "../lib/SaplingMath.sol";
import "../lib/WithdrawalRequestQueue.sol";

/**
 * @title Sapling Pool Context
 * @notice Provides common pool functionality with lender deposits, manager's first loss capital staking,
 *         and reward distribution.
 */
abstract contract SaplingPoolContext is IPoolContext, SaplingManagerContext, ReentrancyGuardUpgradeable {

    using WithdrawalRequestQueue for WithdrawalRequestQueue.LinkedMap;

    /// Tokens configuration
    TokenConfig public tokenConfig;

    /// Pool configuration
    PoolConfig public config;

    /// Key pool balances
    PoolBalance public balances;

    /// Per user withdrawal request states
    mapping (address => WithdrawalRequestState) public withdrawalRequestStates;

    /// Withdrawal request queue
    WithdrawalRequestQueue.LinkedMap private withdrawalQueue;

    modifier noWithdrawalRequests() {
        require(
            withdrawalRequestStates[msg.sender].countOutstanding == 0,
            "SaplingPoolContext: deposit not allowed while having withdrawal requests"
        );
        _;
    }

    /**
     * @notice Creates a SaplingPoolContext.
     * @dev Addresses must not be 0.
     * @param _poolToken ERC20 token contract address to be used as the pool issued token.
     * @param _liquidityToken ERC20 token contract address to be used as pool liquidity currency.
     * @param _accessControl Access control contract
     * @param _managerRole Manager role
     */
    function __SaplingPoolContext_init(
        address _poolToken,
        address _liquidityToken,
        address _accessControl,
        bytes32 _managerRole
    )
        internal
        onlyInitializing
    {
        __SaplingManagerContext_init(_accessControl, _managerRole);

        /*
            Additional check for single init:
                do not init again if a non-zero value is present in the values yet to be initialized.
        */
        assert(tokenConfig.poolToken == address(0) && tokenConfig.liquidityToken == address(0));

        require(_poolToken != address(0), "SaplingPoolContext: pool token address is not set");
        require(_liquidityToken != address(0), "SaplingPoolContext: liquidity token address is not set");

        uint8 decimals = IERC20Metadata(_liquidityToken).decimals();
        tokenConfig = TokenConfig({
            poolToken: _poolToken,
            liquidityToken: _liquidityToken,
            decimals: decimals
        });

        assert(totalPoolTokenSupply() == 0);
        
        uint16 _maxProtocolFeePercent = uint16(10 * 10 ** SaplingMath.PERCENT_DECIMALS);
        uint16 _maxEarnFactor = uint16(1000 * 10 ** SaplingMath.PERCENT_DECIMALS);

        config = PoolConfig({
            weightedAvgStrategyAPR: 0,
            exitFeePercent: SaplingMath.HUNDRED_PERCENT / 200, // 0.5%
            maxProtocolFeePercent: _maxProtocolFeePercent,

            minWithdrawalRequestAmount: 10 * 10 ** tokenConfig.decimals,
            targetStakePercent: uint16(10 * 10 ** SaplingMath.PERCENT_DECIMALS),
            protocolFeePercent: _maxProtocolFeePercent,
            managerEarnFactorMax: _maxEarnFactor,

            targetLiquidityPercent: 0,
            managerEarnFactor: uint16(MathUpgradeable.min(150 * 10 ** SaplingMath.PERCENT_DECIMALS, _maxEarnFactor))
        });
    }

    /**
     * @notice Set the target stake percent for the pool.
     * @dev _targetStakePercent must be greater than 0 and less than or equal to SaplingMath.HUNDRED_PERCENT.
     *      Caller must be the governance.
     * @param _targetStakePercent New target stake percent.
     */
    function setTargetStakePercent(uint16 _targetStakePercent) external onlyRole(SaplingRoles.GOVERNANCE_ROLE) {
        require(
            0 < _targetStakePercent && _targetStakePercent <= SaplingMath.HUNDRED_PERCENT,
            "SaplingPoolContext: target stake percent is out of bounds"
        );

        uint16 prevValue = config.targetStakePercent;
        config.targetStakePercent = _targetStakePercent;

        emit TargetStakePercentSet(prevValue, config.targetStakePercent);
    }

    /**
     * @notice Set the target liquidity percent for the pool.
     * @dev _targetLiquidityPercent must be inclusively between 0 and SaplingMath.HUNDRED_PERCENT.
     *      Caller must be the manager.
     * @param _targetLiquidityPercent new target liquidity percent.
     */
    function setTargetLiquidityPercent(uint16 _targetLiquidityPercent) external onlyRole(poolManagerRole) {
        require(
            0 <= _targetLiquidityPercent && _targetLiquidityPercent <= SaplingMath.HUNDRED_PERCENT,
            "SaplingPoolContext: target liquidity percent is out of bounds"
        );

        uint16 prevValue = config.targetLiquidityPercent;
        config.targetLiquidityPercent = _targetLiquidityPercent;

        emit TargetLiqudityPercentSet(prevValue, config.targetLiquidityPercent);
    }

    /**
     * @notice Set the protocol earning percent for the pool.
     * @dev _protocolEarningPercent must be inclusively between 0 and maxProtocolFeePercent.
     *      Caller must be the governance.
     * @param _protocolEarningPercent new protocol earning percent.
     */
    function setProtocolEarningPercent(uint16 _protocolEarningPercent) external onlyRole(SaplingRoles.GOVERNANCE_ROLE) {
        require(
            0 <= _protocolEarningPercent && _protocolEarningPercent <= config.maxProtocolFeePercent,
            "SaplingPoolContext: protocol earning percent is out of bounds"
        );

        uint16 prevValue = config.protocolFeePercent;
        config.protocolFeePercent = _protocolEarningPercent;

        emit ProtocolFeePercentSet(prevValue, config.protocolFeePercent);
    }

    /**
     * @notice Set an upper bound for the manager's earn factor percent.
     * @dev _managerEarnFactorMax must be greater than or equal to SaplingMath.HUNDRED_PERCENT. If the current 
     *      earn factor is greater than the new maximum, then the current earn factor is set to the new maximum.
     *      Caller must be the governance.
     * @param _managerEarnFactorMax new maximum for manager's earn factor.
     */
    function setManagerEarnFactorMax(uint16 _managerEarnFactorMax) external onlyRole(SaplingRoles.GOVERNANCE_ROLE) {
        require(
            SaplingMath.HUNDRED_PERCENT <= _managerEarnFactorMax,
            "SaplingPoolContext: _managerEarnFactorMax is out of bounds"
        );

        uint16 prevValue = config.managerEarnFactorMax;
        config.managerEarnFactorMax = _managerEarnFactorMax;

        if (config.managerEarnFactor > config.managerEarnFactorMax) {
            uint16 prevEarnFactor = config.managerEarnFactor;
            config.managerEarnFactor = config.managerEarnFactorMax;

            emit ManagerEarnFactorSet(prevEarnFactor, config.managerEarnFactor);
        }

        emit ManagerEarnFactorMaxSet(prevValue, config.managerEarnFactorMax);
    }

    /**
     * @notice Set the manager's earn factor percent.
     * @dev _managerEarnFactorMax must be inclusively between SaplingMath.HUNDRED_PERCENT and managerEarnFactorMax.
     *      Caller must be the manager.
     * @param _managerEarnFactor new manager's earn factor.
     */
    function setManagerEarnFactor(uint16 _managerEarnFactor) external onlyRole(poolManagerRole) {
        require(
            SaplingMath.HUNDRED_PERCENT <= _managerEarnFactor && _managerEarnFactor <= config.managerEarnFactorMax,
            "SaplingPoolContext: _managerEarnFactor is out of bounds"
        );

        uint16 prevValue = config.managerEarnFactor;
        config.managerEarnFactor = _managerEarnFactor;

        emit ManagerEarnFactorSet(prevValue, config.managerEarnFactor);
    }

    /**
     * @notice Deposit liquidity tokens to the pool. Depositing liquidity tokens will mint an equivalent amount of pool
     *         tokens and transfer it to the caller. Exact exchange rate depends on the current pool state.
     * @dev Deposit amount must be non zero and not exceed amountDepositable().
     *      An appropriate spend limit must be present at the token contract.
     *      Caller must not be any of: manager, protocol, governance.
     *      Caller must not have any outstanding withdrawal requests.
     * @param amount Liquidity token amount to deposit.
     */
    function deposit(uint256 amount) external onlyUser noWithdrawalRequests whenNotPaused whenNotClosed {
        uint256 sharesMinted = enter(amount);

        emit FundsDeposited(msg.sender, amount, sharesMinted);
    }

    /**
     * @notice Withdraw liquidity tokens from the pool. Withdrawals redeem equivalent amount of the caller's pool tokens
     *         by burning the tokens in question.
     *         Exact exchange rate depends on the current pool state.
     * @dev Withdrawal amount must be non zero and not exceed amountWithdrawable().
     * @param amount Liquidity token amount to withdraw.
     */
    function withdraw(uint256 amount) public onlyUser whenNotPaused {
        uint256 sharesBurned = exit(amount);

        emit FundsWithdrawn(msg.sender, amount, sharesBurned);
    }

    /** 
     * @notice Request funds for withdrawal by locking in pool tokens.
     * @param shares Amount of pool tokens to lock. 
     */
    function requestWithdrawal(uint256 shares) external onlyUser whenNotPaused {

        uint256 amount = tokensToFunds(shares);
        uint256 outstandingRequestsAmount = tokensToFunds(balances.withdrawalRequestedShares);

        //// base case
        if (
            balances.rawLiquidity >= outstandingRequestsAmount 
            && amount <= balances.rawLiquidity - outstandingRequestsAmount
        )
        {
            withdraw(amount);
            return;
        }

        //// check
        require(
            shares <= IERC20(tokenConfig.poolToken).balanceOf(msg.sender), 
            "SaplingPoolContext: insufficient balance"
        );

        require(amount >= config.minWithdrawalRequestAmount, "SaplingPoolContext: amount is less than the minimum");

        WithdrawalRequestState storage state = withdrawalRequestStates[msg.sender];
        require(state.countOutstanding <= 3, "SaplingPoolContext: too many outstanding withdrawal requests");

        //// effect

        //TODO update if the last position belongs to the user, else queue

        withdrawalQueue.queue(msg.sender, shares);

        state.countOutstanding++;
        state.sharesLocked += shares;
        balances.withdrawalRequestedShares += shares;

        //// interactions

        SafeERC20Upgradeable.safeTransferFrom(
            IERC20Upgradeable(tokenConfig.poolToken),
            msg.sender,
            address(this),
            shares
        );

        //TODO event
    }

    /**
     * @notice Update a withdrawal request.
     * @dev Existing request funds can only be decreseased. Minimum request amount rule must be maintained. 
     *      Requested position must belong to the caller.
     * @param id ID of the withdrawal request to update.
     * @param newShareAmount New total pool token amount to be locked in the request.
     */
    function updateWithdrawalRequest(uint256 id, uint256 newShareAmount) external whenNotPaused {
        //// check        
        WithdrawalRequestQueue.Request memory request = withdrawalQueue.get(id);
        require(request.wallet == msg.sender, "SaplingPoolContext: unauthorized");
        require(
            newShareAmount < request.sharesLocked && tokensToFunds(newShareAmount) >= config.minWithdrawalRequestAmount,
            "SaplingPoolContext: invalid share amount"
        );

        //// effect
        
        uint256 shareDifference = withdrawalQueue.update(id, newShareAmount);

        withdrawalRequestStates[request.wallet].sharesLocked -= shareDifference;
        balances.withdrawalRequestedShares -= shareDifference;


        //// interactions

        // unlock shares
        SafeERC20Upgradeable.safeTransfer(
            IERC20Upgradeable(tokenConfig.poolToken),
            request.wallet,
            shareDifference
        );
    }

    /**
     * @notice Cancel a withdrawal request.
     * @dev Requested position must belong to the caller.
     * @param id ID of the withdrawal request to update.
     */
    function cancelWithdrawalRequest(uint256 id) external whenNotPaused {

        //// check
        WithdrawalRequestQueue.Request memory request = withdrawalQueue.get(id);
        require(request.wallet == msg.sender, "SaplingPoolContext: unauthorized");

        //// effect
        withdrawalQueue.remove(id);
        
        WithdrawalRequestState storage state = withdrawalRequestStates[request.wallet];
        state.countOutstanding--;
        state.sharesLocked -= request.sharesLocked;
        balances.withdrawalRequestedShares -= request.sharesLocked;


        //// interactions

        // unlock shares
        SafeERC20Upgradeable.safeTransfer(
            IERC20Upgradeable(tokenConfig.poolToken),
            request.wallet,
            request.sharesLocked
        );
    }

    /**
     * @notice Fulfill withdrawal request in a batch if liquidity requirements are met.
     * @dev Anyone can trigger fulfillment of a withdrawal request. Fulfillment is on demand, and requests ahead 
     *      in the queue do not have to be fulfilled as long as their liquidity requirements met.
     *      
     *      It is in the interest of the pool manager to keep the withdrawal requests fulfilled as soon as there is 
     *      liquidity, as unfulfilled requests will keep earning yield but lock liquidity once the liquidity comes in.
     *
     * @param count The number of positions to fulfill starting from the head of the queue. 
     *        If the count is greater than queue length, then the entrire queue is processed.
     */
    function fulfillWithdrawalRequests(uint256 count) external whenNotPaused nonReentrant {

        uint256 remaining = MathUpgradeable.min(count, withdrawalQueue.length());
        while (remaining > 0) {
            fulfillNextWithdrawalRequest();
            remaining--;
        }
    }

    /**
     * @dev Fulfill a single withdrawal request at the top of the queue.
     */
    function fulfillNextWithdrawalRequest() private {

        //// check

        WithdrawalRequestQueue.Request memory request = withdrawalQueue.head();
        
        uint256 requestedAmount = tokensToFunds(request.sharesLocked);
        uint256 transferAmount = requestedAmount - MathUpgradeable.mulDiv(
            requestedAmount, 
            config.exitFeePercent, 
            SaplingMath.HUNDRED_PERCENT
        );

        require(balances.rawLiquidity >= transferAmount, "SaplingPolContext: insufficient liqudity");

        //// effect

        withdrawalQueue.remove(request.id);

        WithdrawalRequestState storage state = withdrawalRequestStates[request.wallet];
        state.countOutstanding--;
        state.sharesLocked -= request.sharesLocked;

        balances.rawLiquidity -= transferAmount;

        //// interactions

        // burn shares
        IPoolToken(tokenConfig.poolToken).burn(address(this), request.sharesLocked);

        SafeERC20Upgradeable.safeTransfer(
            IERC20Upgradeable(tokenConfig.liquidityToken),
            request.wallet,
            transferAmount
        );
    }

    /**
     * @notice Stake liquidity tokens into the pool. Staking liquidity tokens will mint an equivalent amount of pool
     *         tokens and lock them in the pool. Exact exchange rate depends on the current pool state.
     * @dev Caller must be the manager.
     *      Stake amount must be non zero.
     *      An appropriate spend limit must be present at the token contract.
     * @param amount Liquidity token amount to stake.
     */
    function stake(uint256 amount) external onlyRole(poolManagerRole) whenNotPaused whenNotClosed {
        require(amount > 0, "SaplingPoolContext: stake amount is 0");

        uint256 sharesMinted = enter(amount);

        emit FundsStaked(msg.sender, amount, sharesMinted);
    }

    /**
     * @notice Unstake liquidity tokens from the pool. Unstaking redeems equivalent amount of the caller's pool tokens
     *         locked in the pool by burning the tokens in question.
     * @dev Caller must be the manager.
     *      Unstake amount must be non zero and not exceed amountUnstakable().
     * @param amount Liquidity token amount to unstake.
     */
    function unstake(uint256 amount) external onlyRole(poolManagerRole) whenNotPaused {
        require(amount > 0, "SaplingPoolContext: unstake amount is 0");
        require(amount <= amountUnstakable(), "SaplingPoolContext: requested amount is not available for unstaking");

        uint256 sharesBurned = exit(amount);

        emit FundsUnstaked(msg.sender, amount, sharesBurned);
    }

    /**
     * @notice Withdraw protocol revenue.
     * @dev Revenue is in liquidity tokens.
     *      Caller must have the treasury role.
     * @param amount Liquidity token amount to withdraw.
     */
    function collectProtocolRevenue(uint256 amount) external onlyRole(SaplingRoles.TREASURY_ROLE) whenNotPaused {
        //// check

        require(amount > 0, "SaplingPoolContext: invalid amount");
        require(amount <= balances.protocolRevenue, "SaplingPoolContext: insufficient balance");


        //// effect

        balances.protocolRevenue -= amount;
        balances.tokenBalance -= amount;

        //// interactions

        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(tokenConfig.liquidityToken), msg.sender, amount);

        emit RevenueWithdrawn(msg.sender, amount);
    }

    /**
     * @notice Withdraw manager's leveraged earnings.
     * @dev Revenue is in liquidity tokens. 
     *      Caller must have the pool manager role.
     * @param amount Liquidity token amount to withdraw.
     */
    function collectManagerRevenue(uint256 amount) external onlyRole(poolManagerRole) whenNotPaused {
        //// check
        
        require(amount > 0, "SaplingPoolContext: invalid amount");
        require(amount <= balances.managerRevenue, "SaplingPoolContext: insufficient balance");


        //// effect

        balances.managerRevenue -= amount;
        balances.tokenBalance -= amount;

        //// interactions

        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(tokenConfig.liquidityToken), msg.sender, amount);

        emit RevenueWithdrawn(msg.sender, amount);
    }

    /**
     * @notice Check liquidity token amount depositable by lenders at this time.
     * @dev Return value depends on the pool state rather than caller's balance.
     * @return Max amount of tokens depositable to the pool.
     */
    function amountDepositable() external view returns (uint256) {
        uint256 poolLimit = poolFundsLimit();
        if (poolLimit <= balances.poolFunds || closed() || paused()) {
            return 0;
        }

        return poolLimit - balances.poolFunds;
    }

    /**
     * @notice Check liquidity token amount withdrawable by the caller at this time.
     * @dev Return value depends on the callers balance, and is limited by pool liquidity.
     * @param wallet Address of the wallet to check the withdrawable balance of.
     * @return Max amount of tokens withdrawable by the caller.
     */
    function amountWithdrawable(address wallet) external view returns (uint256) {
        return paused() ? 0 : MathUpgradeable.min(freeLenderLiquidity(), balanceOf(wallet));
    }

    /**
     * @notice Accessor
     * @return Current length of the withdrawal queue
     */
    function withdrawalRequestsLength() external view returns (uint256) {
        return withdrawalQueue.length();
    }

    /**
     * @notice Accessor
     * @param i Index of the withdrawal request in the queue
     * @return WithdrawalRequestQueue object
     */
    function getWithdrawalRequestAt(uint256 i) external view returns (WithdrawalRequestQueue.Request memory) {
        return withdrawalQueue.at(i);
    }

    /**
     * @notice Accessor
     * @param id ID of the withdrawal request
     * @return WithdrawalRequestQueue object
     */
    function getWithdrawalRequestById(uint256 id) external view returns (WithdrawalRequestQueue.Request memory) {
        return withdrawalQueue.get(id);
    }

    /**
     * @notice Check the manager's staked liquidity token balance in the pool.
     * @return Liquidity token balance of the manager's stake.
     */
    function balanceStaked() external view returns (uint256) {
        return tokensToFunds(balances.stakedShares);
    }

    /**
     * @notice Estimate APY breakdown given the current pool state.
     * @return Current APY breakdown
     */
    function currentAPY() external view returns (APYBreakdown memory) {
        return projectedAPYBreakdown(
            totalPoolTokenSupply(),
            balances.stakedShares,
            balances.poolFunds,
            balances.strategizedFunds, 
            config.weightedAvgStrategyAPR,
            config.protocolFeePercent,
            config.managerEarnFactor
        );
    }

    //TODO decide if the funtion below is redundant
    /**
     * @notice Projected APY breakdown given the current pool state and a specific strategy rate and an average apr.
     * @dev Represent percentage parameter values in contract specific format.
     * @param strategyRate Percentage of pool funds projected to be used in strategies.
     * @param _avgStrategyAPR Weighted average APR of the funds in strategies.
     * @return Projected APY breakdown
     */
    function simpleProjectedAPY(
        uint16 strategyRate, 
        uint256 _avgStrategyAPR) external view returns (APYBreakdown memory) {
        require(strategyRate <= SaplingMath.HUNDRED_PERCENT, "SaplingPoolContext: invalid borrow rate");

        return projectedAPYBreakdown(
            totalPoolTokenSupply(),
            balances.stakedShares,
            balances.poolFunds,
            MathUpgradeable.mulDiv(balances.poolFunds, strategyRate, SaplingMath.HUNDRED_PERCENT), 
            _avgStrategyAPR,
            config.protocolFeePercent,
            config.managerEarnFactor
        );
    }

    /**
     * @notice Check wallet's liquidity token balance in the pool. This balance includes deposited balance and acquired
     *         yield. This balance does not included staked balance, leveraged revenue or protocol revenue.
     * @param wallet Address of the wallet to check the balance of.
     * @return Liquidity token balance of the wallet in this pool.
     */
    function balanceOf(address wallet) public view returns (uint256) {
        return tokensToFunds(IPoolToken(tokenConfig.poolToken).balanceOf(wallet));
    }

    /**
     * @notice Check liquidity token amount unstakable by the manager at this time.
     * @dev Return value depends on the manager's stake balance and targetStakePercent, and is limited by pool
     *      liquidity.
     * @return Max amount of tokens unstakable by the manager.
     */
    function amountUnstakable() public view returns (uint256) {
        uint256 totalPoolShares = totalPoolTokenSupply();
        uint256 withdrawableLiquidity = freeLenderLiquidity();

        if (
            paused() ||
            config.targetStakePercent >= SaplingMath.HUNDRED_PERCENT && totalPoolShares > balances.stakedShares
        ) {
            return 0;
        } else if (closed() || totalPoolShares == balances.stakedShares) {
            return MathUpgradeable.min(withdrawableLiquidity, tokensToFunds(balances.stakedShares)); 
        }

        uint256 lenderShares = totalPoolShares - balances.stakedShares;
        uint256 lockedStakeShares = MathUpgradeable.mulDiv(
            lenderShares,
            config.targetStakePercent,
            SaplingMath.HUNDRED_PERCENT - config.targetStakePercent
        );

        return MathUpgradeable.min(
            withdrawableLiquidity,
            tokensToFunds(balances.stakedShares - lockedStakeShares)
        );
    }

    /**
     * @notice Current liquidity available for pool strategies such as lending or investing.
     * @return Strategy liquidity amount.
     */
    function strategyLiquidity() public view returns (uint256) {

        uint256 lenderAllocatedLiquidity = MathUpgradeable.max(
            tokensToFunds(balances.withdrawalRequestedShares),
            MathUpgradeable.mulDiv(
                balances.poolFunds,
                config.targetLiquidityPercent,
                SaplingMath.HUNDRED_PERCENT
            )
        );

        return balances.rawLiquidity > lenderAllocatedLiquidity 
            ? balances.rawLiquidity - lenderAllocatedLiquidity 
            : 0;
    }

    /**
     * @notice Accessor
     * @return Shared liquidity available for all lenders to withdraw immediately without queuing withdrawal requests.
     */
    function freeLenderLiquidity() public view returns (uint256) {

        uint256 withdrawalRequestedLiqudity = tokensToFunds(balances.withdrawalRequestedShares);

        return balances.rawLiquidity > withdrawalRequestedLiqudity 
            ? balances.rawLiquidity - withdrawalRequestedLiqudity
            : 0;
    }

    /**
     * @dev View pool funds limit based on the staked funds.
     * @return MAX amount of liquidity tokens allowed in the pool based on staked assets
     */
    function poolFundsLimit() public view returns (uint256) {
        return tokensToFunds(
            MathUpgradeable.mulDiv(balances.stakedShares, SaplingMath.HUNDRED_PERCENT, config.targetStakePercent)
        );
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
    function enter(uint256 amount) internal nonReentrant returns (uint256) {
        //// check

        require(amount > 0, "SaplingPoolContext: pool deposit amount is 0");

        bool isManager = hasRole(poolManagerRole, msg.sender);

        // non-managers must follow pool size limit
        if (!isManager) {
            uint256 poolLimit = poolFundsLimit();
            require(
                poolLimit > balances.poolFunds && amount <= poolLimit - balances.poolFunds,
                "SaplingPoolContext: deposit amount is over the remaining pool limit"
            );
        }
        
        //// effect

        uint256 shares = fundsToTokens(amount);

        balances.tokenBalance += amount;
        balances.rawLiquidity += amount;
        balances.poolFunds += amount;

        if (isManager) {
            // this is a staking entry

            balances.stakedShares += shares;
        }

        //// interactions

        // charge 'amount' tokens from msg.sender
        SafeERC20Upgradeable.safeTransferFrom(
            IERC20Upgradeable(tokenConfig.liquidityToken),
            msg.sender,
            address(this),
            amount
        );

        // mint shares
        IPoolToken(tokenConfig.poolToken).mint(!isManager ? msg.sender : address(this), shares);

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
    function exit(uint256 amount) internal nonReentrant returns (uint256) {
        //// check
        require(amount > 0, "SaplingPoolContext: pool withdrawal amount is 0");
        require(balances.rawLiquidity >= amount, "SaplingPoolContext: insufficient liquidity");

        uint256 shares = fundsToTokens(amount);

        bool isManager = hasRole(poolManagerRole, msg.sender);

        require(
            isManager
                ? shares <= balances.stakedShares
                : shares <= IERC20(tokenConfig.poolToken).balanceOf(msg.sender),
            "SaplingPoolContext: insufficient balance"
        );

        //// effect

        if (isManager) {
            balances.stakedShares -= shares;
        }

        uint256 transferAmount = amount - MathUpgradeable.mulDiv(
            amount, 
            config.exitFeePercent, 
            SaplingMath.HUNDRED_PERCENT
        );

        balances.poolFunds -= transferAmount;
        balances.rawLiquidity -= transferAmount;
        balances.tokenBalance -= transferAmount;

        //// interactions

        // burn shares
        IPoolToken(tokenConfig.poolToken).burn(isManager ? address(this) : msg.sender, shares);

        // transfer liqudity tokens
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(tokenConfig.liquidityToken), msg.sender, transferAmount);

        return shares;
    }

    /**
     * @dev Internal method to update the weighted average loan apr based on the amount reduced by and an apr.
     * @param amountReducedBy amount by which the funds committed into strategy were reduced, due to repayment or loss
     * @param apr annual percentage rate of the strategy
     */
    function updateAvgStrategyApr(uint256 amountReducedBy, uint16 apr) internal {
        if (balances.strategizedFunds > 0) {
            config.weightedAvgStrategyAPR = (
                (balances.strategizedFunds + amountReducedBy) * config.weightedAvgStrategyAPR - amountReducedBy * apr
            )
                / balances.strategizedFunds;
        } else {
            config.weightedAvgStrategyAPR = 0;
        }
    }

    /**
     * @notice Get liquidity token value of shares.
     * @param poolTokens Pool token amount
     */
    function tokensToFunds(uint256 poolTokens) public view override returns (uint256) {
        if (poolTokens == 0 || balances.poolFunds == 0) {
             return 0;
        }

        return MathUpgradeable.mulDiv(poolTokens, balances.poolFunds, totalPoolTokenSupply());
    }

    /**
     * @notice Get pool token value of liquidity tokens.
     * @param liquidityTokens Amount of liquidity tokens.
     */
    function fundsToTokens(uint256 liquidityTokens) public view override returns (uint256) {
        uint256 totalPoolTokens = totalPoolTokenSupply();

        if (totalPoolTokens == 0) {
            // a pool with no positions
            return liquidityTokens;
        } else if (balances.poolFunds == 0) {
            /*
                Handle failed pool case, where: poolFunds == 0, but totalPoolShares > 0
                To minimize loss for the new depositor, assume the total value of existing shares is the minimum
                possible nonzero integer, which is 1.

                Simplify (tokens * totalPoolShares) / 1 as tokens * totalPoolShares.
            */
            return liquidityTokens * totalPoolTokens;
        }

        return MathUpgradeable.mulDiv(liquidityTokens, totalPoolTokens, balances.poolFunds);
    }

    /**
     * @notice Check if the pool has sufficient stake
     * @return True if the staked funds provide at least a minimum ratio to the pool funds, False otherwise.
     */
    function maintainsStakeRatio() public view returns (bool) {
        return balances.stakedShares >= MathUpgradeable.mulDiv(
                    totalPoolTokenSupply(),
                    config.targetStakePercent,
                    SaplingMath.HUNDRED_PERCENT
                );
    }

    // contract compiled size optimization accessor
    function totalPoolTokenSupply() internal view returns (uint256) {
        return IERC20(tokenConfig.poolToken).totalSupply();
    }

    /**
     * @notice APY breakdown given a specified scenario.
     * @dev Represent percentage parameter values in contract specific format.
     * @param _totalPoolTokens total pull token supply. For current conditions use: totalPoolTokenSupply()
     * @param _stakedTokens the amount of staked pool tokens. Must be less than or equal to _totalPoolTokens. 
     *                      For current conditions use: balances.stakedShares
     * @param _poolFunds liquidity token funds that make up the pool. For current conditions use: balances.poolFunds
     * @param _strategizedFunds part of the pool funds that will remain in strategies. Must be less than or equal to 
     *                          _poolFunds. For current conditions use: balances.strategizedFunds
     * @param _avgStrategyAPR Weighted average APR of the funds in strategies. 
     *                        For current conditions use: config.weightedAvgStrategyAPR
     * @param _protocolFeePercent Protocol fee parameter. Must be less than 100%.
     *                            For current conditions use: config.protocolFeePercent
     * @param _managerEarnFactor Manager's earn factor. Must be greater than or equal to 1x (100%). 
     *                           For current conditions use: config.managerEarnFactor
     * @return Pool apy with protocol, manager, and lender components broken down.
     */
    function projectedAPYBreakdown(
        uint256 _totalPoolTokens,
        uint256 _stakedTokens,
        uint256 _poolFunds,
        uint256 _strategizedFunds,
        uint256 _avgStrategyAPR,
        uint16 _protocolFeePercent,
        uint16 _managerEarnFactor
    ) 
        public 
        pure 
        returns (APYBreakdown memory) 
    {
        require(_stakedTokens <= _totalPoolTokens, "SaplingPoolContext: invalid parameter _stakedTokens");
        require(_strategizedFunds <= _poolFunds, "SaplingPoolContext: invalid parameter _strategizedFunds");
        require(
            _protocolFeePercent <= SaplingMath.HUNDRED_PERCENT,
            "SaplingPoolContext: invalid parameter _protocolFeePercent"
        );
        require(
            _managerEarnFactor >= SaplingMath.HUNDRED_PERCENT,
            "SaplingPoolContext: invalid parameter _managerEarnFactor"
        );

        if (_poolFunds == 0 || _strategizedFunds == 0 || _avgStrategyAPR == 0) {
            return APYBreakdown(0, 0, 0, 0);
        }

        // pool APY
        uint256 poolAPY = MathUpgradeable.mulDiv(_avgStrategyAPR, _strategizedFunds, _poolFunds);

        // protocol APY
        uint256 protocolAPY = MathUpgradeable.mulDiv(poolAPY, _protocolFeePercent, SaplingMath.HUNDRED_PERCENT);

        uint256 remainingAPY = poolAPY - protocolAPY;

        // manager withdrawableAPY
        uint256 currentStakePercent = MathUpgradeable.mulDiv(
            _stakedTokens,
            SaplingMath.HUNDRED_PERCENT,
            _totalPoolTokens
        );
        uint256 managerEarningsPercent = MathUpgradeable.mulDiv(
            currentStakePercent,
            _managerEarnFactor - SaplingMath.HUNDRED_PERCENT,
            SaplingMath.HUNDRED_PERCENT);

        uint256 managerWithdrawableAPY = MathUpgradeable.mulDiv(
            remainingAPY,
            managerEarningsPercent,
            managerEarningsPercent + SaplingMath.HUNDRED_PERCENT
        );

        uint256 _lenderAPY = remainingAPY - managerWithdrawableAPY;

        return APYBreakdown({
            totalPoolAPY: uint16(poolAPY), 
            protocolRevenueComponent: uint16(protocolAPY), 
            managerRevenueComponent: uint16(managerWithdrawableAPY), 
            lenderComponent: uint16(_lenderAPY)
        });
    }

    /**
     * @dev Implementation of the abstract hook in SaplingManagedContext.
     *      Pool can be close when no funds remain committed to strategies.
     */
    function canClose() internal view override returns (bool) {
        return balances.strategizedFunds == 0;
    }

    /**
     * @dev Slots reserved for future state variables
     */
    uint256[35] private __gap;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * Withdrawal request queue for Sapling lending pools. 
 * The queue is virtual, and implements a doubly linked map with functions limited to intended business logic. 
 */
library WithdrawalRequestQueue {

    using EnumerableSet for EnumerableSet.UintSet;

    /// Withdrawal request position
    struct Request {

        /// Request ID
        uint256 id; 

        /// Requestor wallet address
        address wallet;

        /// Amount of pool tokens locked in this request
        uint256 sharesLocked;

        /* Linked list fields */

        /// ID of the previous node
        uint256 prev;

        /// ID of the next node
        uint256 next;
    }

    /// Doubly linked map of withdrawal requests
    struct LinkedMap {

        /// ID of the last withdrawalRequest, for unique id generation
        uint256 _lastRequestId;

        /// ID of the head node
        uint256 _head;

        /// ID of the tail node
        uint256 _tail;

        /// Set of node IDs (unsorted)
        EnumerableSet.UintSet _ids;

        /// map of nodes (requests) by ID
        mapping (uint256 => Request) _requests;
    }

    /**
     * @notice Queue a new withdrawal request
     * @param list storage reference to LinkedMap
     * @param user requestor wallet address
     * @param shares poolTokens locked in the withdrawal request
     * @return id of the newly queued request
     */
    function queue(LinkedMap storage list, address user, uint256 shares) internal returns (uint256) {
        uint256 newId = list._lastRequestId + 1;

        list._requests[newId] = Request({
            id: newId,
            wallet: user,
            sharesLocked: shares,
            prev: list._tail,
            next: 0
        });

        list._lastRequestId = newId;
        list._ids.add(newId);

        if (list._head == 0) {
            list._head = newId;
        }

        if (list._tail != 0) {
            list._requests[list._tail].next = newId;
        }

        list._tail = newId;

        return newId;
    }

    /**
     * @notice Update an existing withdrawal request
     * @dev Locked token amount can only be decreased but must stay above 0. Use remove for a value of 0 instead.
     * @param list Storage reference to LinkedMap
     * @param id Requestor wallet address
     * @param newShareAmount new amount of poolTokens locked in the withdrawal request
     * @return Difference in the locked pool tokens after the update
     */
    function update(LinkedMap storage list, uint256 id, uint256 newShareAmount) internal returns (uint256) {
        require(list._ids.contains(id), "WithdrawalRequestQueue: not found");

        Request storage request = list._requests[id];
        require(
            0 < newShareAmount && newShareAmount < request.sharesLocked, 
            "WithdrawalRequestQueue: invalid shares amount"
        );
        
        uint256 shareDifference = request.sharesLocked - newShareAmount;
        request.sharesLocked = newShareAmount;

        return shareDifference;
    }

    /**
     * @notice Remove an existing withdrawal request
     * @param list Storage reference to LinkedMap
     * @param id Requestor wallet address
     */
    function remove(LinkedMap storage list, uint256 id) internal {
        require(list._ids.contains(id), "WithdrawalRequestQueue: not found");

        Request storage request = list._requests[id];

        if (request.next > 0) {
            list._requests[request.next].prev = request.prev;
        }

        if (request.prev > 0) {
            list._requests[request.prev].next = request.next;
        }
        
        list._ids.remove(id);

        if (id == list._head) {
            list._head = request.next;
        }

        if (id == list._tail) {
            list._tail = request.prev;
        }

        delete list._requests[id];
    }

    /**
     * @notice Accessor
     * @param list storage reference to LinkedMap
     * @return Length of the queue
     */
    function length(LinkedMap storage list) internal view returns(uint256) {
        return list._ids.length();
    }

    /**
     * @notice Accessor
     * @dev ID value of 0 is not used, and a return value of 0 means the queue is empty.
     * @param list Storage reference to LinkedMap
     * @return ID of the first (head) node in the queue
     */
    function head(LinkedMap storage list) internal view returns (Request memory) {
        require(list._head != 0, "WithdrawalRequestQueue: list is empty");
        return list._requests[list._head];
    }

    /**
     * @notice Accessor
     * @dev ID value of 0 is not used, and a return value of 0 means the queue is empty.
     * @param list storage reference to LinkedMap
     * @return Node (withdrawal request) with the given ID
     */
    function tail(LinkedMap storage list) internal view returns (Request memory) {
        require(list._tail != 0, "WithdrawalRequestQueue: list is empty");
        return list._requests[list._tail];
    }

    /**
     * @notice Accessor
     * @dev ID must belong to a node that is still in the queue.
     * @param list Storage reference to LinkedMap
     * @param id Id of the node to get
     * @return Node (withdrawal request) with the given ID
     */
    function get(LinkedMap storage list, uint256 id) internal view returns(Request memory) {
        require(list._ids.contains(id), "WithdrawalRequestQueue: not found");
        return list._requests[id];
    }

    /**
     * @notice Accessor
     * @dev Index must be within bounds/less than the queue length.
     * @param list Storage reference to LinkedMap
     * @param index Index of the node to get.
     * @return Node (withdrawal request) at the given index
     */
    function at(LinkedMap storage list, uint256 index) internal view returns(Request memory) {
        require(index < list._ids.length(), "WithdrawalRequestQueue: index out of bounds");

        uint256 current = list._head;
        for (uint256 i = 0; i < index; i++) {
            current = list._requests[current].next;
        }

        return list._requests[current];
    }
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
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}