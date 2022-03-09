pragma solidity 0.8.4;

import "./libraries/ErrorReporter.sol";
import "./libraries/ExponentialNoError.sol";
import "./interfaces/IComptroller.sol";
import "./ComptrollerStorage.sol";

interface IOvix {
    function transfer(address, uint256) external;

    function balanceOf(address) external view returns (uint256);
}

interface IUnitroller {
    function admin() external view returns (address);

    function _acceptImplementation() external returns (uint256);
}

/**
 * @title Compound's Comptroller Contract
 * @author Compound
 */
contract Comptroller is
    ComptrollerV7Storage,
    IComptroller,
    ComptrollerErrorReporter,
    ExponentialNoError
{
    /// @notice Emitted when an admin modifies a reward updater
    event RewardUpdaterModified(address _rewardUpdater);

    /// @notice Emitted when an admin supports a market
    event MarketListed(IOToken oToken);

    /// @notice Emitted when an account enters a market
    event MarketEntered(IOToken oToken, address account);

    /// @notice Emitted when an account exits a market
    event MarketExited(IOToken oToken, address account);

    /// @notice Emitted when close factor is changed by admin
    event NewCloseFactor(
        uint256 oldCloseFactorMantissa,
        uint256 newCloseFactorMantissa
    );

    /// @notice Emitted when a collateral factor is changed by admin
    event NewCollateralFactor(
        IOToken oToken,
        uint256 oldCollateralFactorMantissa,
        uint256 newCollateralFactorMantissa
    );

    /// @notice Emitted when liquidation incentive is changed by admin
    event NewLiquidationIncentive(
        uint256 oldLiquidationIncentiveMantissa,
        uint256 newLiquidationIncentiveMantissa
    );

    /// @notice Emitted when price oracle is changed
    event NewPriceOracle(
        PriceOracle oldPriceOracle,
        PriceOracle newPriceOracle
    );

    /// @notice Emitted when pause guardian is changed
    event NewPauseGuardian(address oldPauseGuardian, address newPauseGuardian);

    /// @notice Emitted when an action is paused globally
    event ActionPaused(string action, bool pauseState);

    /// @notice Emitted when an action is paused on a market
    event ActionPaused(IOToken oToken, string action, bool pauseState);

    /// @notice Emitted when a new borrow-side Reward speed is calculated for a market
    event RewardBorrowSpeedUpdated(IOToken indexed oToken, uint256 newSpeed);

    /// @notice Emitted when a new supply-side Reward speed is calculated for a market
    event RewardSupplySpeedUpdated(IOToken indexed oToken, uint256 newSpeed);

    /// @notice Emitted when a new Reward speed is set for a contributor
    event ContributorRewardSpeedUpdated(
        address indexed contributor,
        uint256 newSpeed
    );

    /// @notice Emitted when VIX is distributed to a supplier
    event DistributedSupplierReward(
        IOToken indexed oToken,
        address indexed supplier,
        uint256 tokenDelta,
        uint256 tokenSupplyIndex
    );

    /// @notice Emitted when VIX is distributed to a borrower
    event DistributedBorrowerReward(
        IOToken indexed oToken,
        address indexed borrower,
        uint256 tokenDelta,
        uint256 tokenBorrowIndex
    );

    /// @notice Emitted when borrow cap for a oToken is changed
    event NewBorrowCap(IOToken indexed oToken, uint256 newBorrowCap);

    /// @notice Emitted when borrow cap guardian is changed
    event NewBorrowCapGuardian(
        address oldBorrowCapGuardian,
        address newBorrowCapGuardian
    );

    /// @notice Emitted when VIX is granted by admin
    event VixGranted(address recipient, uint256 amount);

    /// @notice Emitted when Reward accrued for a user has been manually adjusted.
    event RewardAccruedAdjusted(
        address indexed user,
        uint256 oldRewardAccrued,
        uint256 newRewardAccrued
    );

    /// @notice Emitted when Reward receivable for a user has been updated.
    event RewardReceivableUpdated(
        address indexed user,
        uint256 oldRewardReceivable,
        uint256 newRewardReceivable
    );

    bool public constant override isComptroller = true;

    /// @notice The initial Reward index for a market
    uint224 public constant marketInitialIndex = 1e36;

    // closeFactorMantissa must be strictly greater than this value
    uint256 internal constant closeFactorMinMantissa = 0.05e18; // 0.05

    // closeFactorMantissa must not exceed this value
    uint256 internal constant closeFactorMaxMantissa = 0.9e18; // 0.9

    // No collateralFactorMantissa may exceed this value
    uint256 internal constant collateralFactorMaxMantissa = 0.9e18; // 0.9

    address oAddress;
    address public rewardUpdater;

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    /*** Assets You Are In ***/

    /**
     * @notice Returns the assets an account has entered
     * @param account The address of the account to pull assets for
     * @return A dynamic list with the assets the account has entered
     */
    function getAssetsIn(address account)
        external
        view
        returns (IOToken[] memory)
    {
        return accountAssets[account];
    }

    /**
     * @notice Returns whether the given token is listed market
     * @param oToken The oToken to check
     * @return True if is market, otherwise false.
     */
    function isMarket(address oToken) external view override returns(bool) {
        return markets[oToken].isListed;
    }

    /**
     * @notice Returns whether the given account is entered in the given asset
     * @param account The address of the account to check
     * @param oToken The oToken to check
     * @return True if the account is in the asset, otherwise false.
     */
    function checkMembership(address account, IOToken oToken)
        external
        view
        returns (bool)
    {
        return accountMembership[address(oToken)][account];
    }

    /**
     * @notice Add assets to be included in account liquidity calculation
     * @param oTokens The list of addresses of the oToken markets to be enabled
     * @return Success indicator for whether each corresponding market was entered
     */
    function enterMarkets(address[] memory oTokens)
        public
        override
        returns (uint256[] memory)
    {
        uint256 len = oTokens.length;

        uint256[] memory results = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            results[i] = uint256(addToMarketInternal(IOToken(oTokens[i]), msg.sender));
        }

        return results;
    }

    /**
     * @notice Add the market to the borrower's "assets in" for liquidity calculations
     * @param oToken The market to enter
     * @param borrower The address of the account to modify
     * @return Success indicator for whether the market was entered
     */
    function addToMarketInternal(IOToken oToken, address borrower)
        internal
        returns (Error)
    {
        if (!markets[address(oToken)].isListed) {
            // market is not listed, cannot join
            return Error.MARKET_NOT_LISTED;
        }

        if (accountMembership[address(oToken)][borrower]) {
            // already joined
            return Error.NO_ERROR;
        }

        // survived the gauntlet, add to list
        // NOTE: we store these somewhat redundantly as a significant optimization
        //  this avoids having to iterate through the list for the most common use cases
        //  that is, only when we need to perform liquidity checks
        //  and not whenever we want to check if an account is in a particular market
        accountMembership[address(oToken)][borrower] = true;
        accountAssets[borrower].push(oToken);

        emit MarketEntered(oToken, borrower);

        return Error.NO_ERROR;
    }

    /**
     * @notice Removes asset from sender's account liquidity calculation
     * @dev Sender must not have an outstanding borrow balance in the asset,
     *  or be providing necessary collateral for an outstanding borrow.
     * @param oTokenAddress The address of the asset to be removed
     * @return Whether or not the account successfully exited the market
     */
    function exitMarket(address oTokenAddress) external override returns (uint256) {
        IOToken oToken = IOToken(oTokenAddress);
        /* Get sender tokensHeld and amountOwed underlying from the oToken */
        (uint256 oErr, uint256 tokensHeld, uint256 amountOwed, ) = oToken
            .getAccountSnapshot(msg.sender);
        require(oErr == 0, "exitMarket: getAccountSnapshot failed"); // semi-opaque error code

        /* Fail if the sender has a borrow balance */
        if (amountOwed != 0) {
            return
                fail(
                    Error.NONZERO_BORROW_BALANCE,
                    FailureInfo.EXIT_MARKET_BALANCE_OWED
                );
        }

        /* Fail if the sender is not permitted to redeem all of their tokens */
        uint256 allowed = redeemAllowedInternal(
            oTokenAddress,
            msg.sender,
            tokensHeld
        );
        if (allowed != 0) {
            return
                failOpaque(
                    Error.REJECTION,
                    FailureInfo.EXIT_MARKET_REJECTION,
                    allowed
                );
        }

        /* Return true if the sender is not already ‘in’ the market */
        if (!accountMembership[address(oToken)][msg.sender]) {
            return uint256(Error.NO_ERROR);
        }

        /* Set oToken account membership to false */
        delete accountMembership[address(oToken)][msg.sender];

        /* Delete oToken from the account’s list of assets */
        // load into memory for faster iteration
        IOToken[] memory userAssetList = accountAssets[msg.sender];
        uint256 len = userAssetList.length;
        uint256 assetIndex = len;
        for (uint256 i = 0; i < len; i++) {
            if (userAssetList[i] == oToken) {
                assetIndex = i;
                break;
            }
        }

        // We *must* have found the asset in the list or our redundant data structure is broken
        assert(assetIndex < len);

        // copy last item in list to location of item to be removed, reduce length by 1
        IOToken[] storage storedList = accountAssets[msg.sender];
        storedList[assetIndex] = storedList[storedList.length - 1];
        storedList.pop();

        emit MarketExited(oToken, msg.sender);

        return uint256(Error.NO_ERROR);
    }

    /*** Policy Hooks ***/

    /**
     * @notice Checks if the account should be allowed to mint tokens in the given market
     * @param oToken The market to verify the mint against
     * @param minter The account which would get the minted tokens
     * @param mintAmount The amount of underlying being supplied to the market in exchange for tokens
     * @return 0 if the mint is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function mintAllowed(
        address oToken,
        address minter,
        uint256 mintAmount
    ) external override returns (uint256) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!guardianPaused[oToken].mint, "mint is paused");

        // Shh - currently unused
        minter;
        mintAmount;

        if (!markets[oToken].isListed) {
            return uint256(Error.MARKET_NOT_LISTED);
        }

        // Keep the flywheel moving
        // updateRewardSupplyIndex(oToken);
        // distributeSupplierReward(oToken, minter);
        updateAndDistributeSupplierRewardsForToken(oToken, minter);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Validates mint and reverts on rejection. May emit logs.
     * @param oToken Asset being minted
     * @param minter The address minting the tokens
     * @param actualMintAmount The amount of the underlying asset being minted
     * @param mintTokens The number of tokens being minted
     */
    function mintVerify(
        address oToken,
        address minter,
        uint256 actualMintAmount,
        uint256 mintTokens
    ) external override {
        // Shh - currently unused
        oToken;
        minter;
        actualMintAmount;
        mintTokens;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets = maxAssets;
        }
    }

    /**
     * @notice Checks if the account should be allowed to redeem tokens in the given market
     * @param oToken The market to verify the redeem against
     * @param redeemer The account which would redeem the tokens
     * @param redeemTokens The number of oTokens to exchange for the underlying asset in the market
     * @return 0 if the redeem is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function redeemAllowed(
        address oToken,
        address redeemer,
        uint256 redeemTokens
    ) external override returns (uint256) {
        uint256 allowed = redeemAllowedInternal(oToken, redeemer, redeemTokens);
        if (allowed != uint256(Error.NO_ERROR)) {
            return allowed;
        }

        // Keep the flywheel moving
        // updateRewardSupplyIndex(oToken);
        // distributeSupplierReward(oToken, redeemer); // todo: remove
        updateAndDistributeSupplierRewardsForToken(oToken, redeemer);

        return uint256(Error.NO_ERROR);
    }

    function redeemAllowedInternal(
        address oToken,
        address redeemer,
        uint256 redeemTokens
    ) internal view returns (uint256) {
        if (!markets[oToken].isListed) {
            return uint256(Error.MARKET_NOT_LISTED);
        }

        /* If the redeemer is not 'in' the market, then we can bypass the liquidity check */
        if (!accountMembership[oToken][redeemer]) {
            return uint256(Error.NO_ERROR);
        }

        /* Otherwise, perform a hypothetical liquidity check to guard against shortfall */
        (
            Error err,
            ,
            uint256 shortfall
        ) = getHypotheticalAccountLiquidityInternal(
                redeemer,
                IOToken(oToken),
                redeemTokens,
                0
            );
        if (err != Error.NO_ERROR) {
            return uint256(err);
        }
        if (shortfall > 0) {
            return uint256(Error.INSUFFICIENT_LIQUIDITY);
        }

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Validates redeem and reverts on rejection. May emit logs.
     * @param oToken Asset being redeemed
     * @param redeemer The address redeeming the tokens
     * @param redeemAmount The amount of the underlying asset being redeemed
     * @param redeemTokens The number of tokens being redeemed
     */
    function redeemVerify(
        address oToken,
        address redeemer,
        uint256 redeemAmount,
        uint256 redeemTokens
    ) external override {
        // Shh - currently unused
        oToken;
        redeemer;

        // Require tokens is zero or amount is also zero
        require(redeemTokens != 0 || redeemAmount == 0, "redeemTokens zero");
    }

    /**
     * @notice Checks if the account should be allowed to borrow the underlying asset of the given market
     * @param oToken The market to verify the borrow against
     * @param borrower The account which would borrow the asset
     * @param borrowAmount The amount of underlying the account would borrow
     * @return 0 if the borrow is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function borrowAllowed(
        address oToken,
        address borrower,
        uint256 borrowAmount
    ) external override returns (uint256) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!guardianPaused[oToken].borrow, "borrow is paused");

        if (!markets[oToken].isListed) {
            return uint256(Error.MARKET_NOT_LISTED);
        }

        if (!accountMembership[oToken][borrower]) {
            // only oTokens may call borrowAllowed if borrower not in market
            require(msg.sender == oToken, "sender must be oToken");

            // attempt to add borrower to the market
            Error err = addToMarketInternal(IOToken(msg.sender), borrower);
            if (err != Error.NO_ERROR) {
                return uint256(err);
            }

            // it should be impossible to break the important invariant
            assert(accountMembership[oToken][borrower]);
        }

        if (oracle.getUnderlyingPrice(IOToken(oToken)) == 0) {
            return uint256(Error.PRICE_ERROR);
        }

        uint256 borrowCap = borrowCaps[oToken];
        // Borrow cap of 0 corresponds to unlimited borrowing
        if (borrowCap != 0) {
            require((IOToken(oToken).totalBorrows() + borrowAmount) < borrowCap, "borrow cap reached");
        }

        (
            Error err,
            ,
            uint256 shortfall
        ) = getHypotheticalAccountLiquidityInternal(
                borrower,
                IOToken(oToken),
                0,
                borrowAmount
            );

        if (err != Error.NO_ERROR) {
            return uint256(err);
        }
        if (shortfall > 0) {
            return uint256(Error.INSUFFICIENT_LIQUIDITY);
        }

        // Keep the flywheel moving
        // Exp memory borrowIndex = Exp({mantissa: IOToken(oToken).borrowIndex()});
        // updateRewardBorrowIndex(oToken, borrowIndex); //todo: remove
        // distributeBorrowerReward(oToken, borrower, borrowIndex);

        updateAndDistributeBorrowerRewardsForToken(oToken, borrower);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Validates borrow and reverts on rejection. May emit logs.
     * @param oToken Asset whose underlying is being borrowed
     * @param borrower The address borrowing the underlying
     * @param borrowAmount The amount of the underlying asset requested to borrow
     */
    function borrowVerify(
        address oToken,
        address borrower,
        uint256 borrowAmount
    ) external override {
        // Shh - currently unused
        oToken;
        borrower;
        borrowAmount;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets = maxAssets;
        }
    }

    /**
     * @notice Checks if the account should be allowed to repay a borrow in the given market
     * @param oToken The market to verify the repay against
     * @param payer The account which would repay the asset
     * @param borrower The account which would borrowed the asset
     * @param repayAmount The amount of the underlying asset the account would repay
     * @return 0 if the repay is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function repayBorrowAllowed(
        address oToken,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external override returns (uint256) {
        // Shh - currently unused
        payer;
        borrower;
        repayAmount;

        if (!markets[oToken].isListed) {
            return uint256(Error.MARKET_NOT_LISTED);
        }

        // Keep the flywheel moving
        // Exp memory borrowIndex = Exp({mantissa: IOToken(oToken).borrowIndex()});
        // updateRewardBorrowIndex(oToken, borrowIndex); //todo: rmeove
        // distributeBorrowerReward(oToken, borrower, borrowIndex);

        updateAndDistributeBorrowerRewardsForToken(oToken, borrower);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Validates repayBorrow and reverts on rejection. May emit logs.
     * @param oToken Asset being repaid
     * @param payer The address repaying the borrow
     * @param borrower The address of the borrower
     * @param actualRepayAmount The amount of underlying being repaid
     */
    function repayBorrowVerify(
        address oToken,
        address payer,
        address borrower,
        uint256 actualRepayAmount,
        uint256 borrowerIndex
    ) external {
        // Shh - currently unused
        oToken;
        payer;
        borrower;
        actualRepayAmount;
        borrowerIndex;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets = maxAssets;
        }
    }

    /**
     * @notice Checks if the liquidation should be allowed to occur
     * @param oTokenBorrowed Asset which was borrowed by the borrower
     * @param oTokenCollateral Asset which was used as collateral and will be seized
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param repayAmount The amount of underlying being repaid
     */
    function liquidateBorrowAllowed(
        address oTokenBorrowed,
        address oTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external override returns (uint256) {
        // Shh - currently unused
        liquidator;

        if (
            !markets[oTokenBorrowed].isListed ||
            !markets[oTokenCollateral].isListed
        ) {
            return uint256(Error.MARKET_NOT_LISTED);
        }

        uint256 borrowBalance = IOToken(oTokenBorrowed).borrowBalanceStored(
            borrower
        );

        /* allow accounts to be liquidated if the market is deprecated */
        if (isDeprecated(IOToken(oTokenBorrowed))) {
            require(
                borrowBalance >= repayAmount,
                "Can not repay more than the total borrow"
            );
        } else {
            /* The borrower must have shortfall in order to be liquidatable */
            (Error err, , uint256 shortfall) = getHypotheticalAccountLiquidityInternal(
                borrower, 
                IOToken(address(0)), 
                0, 
                0
            );

            if (err != Error.NO_ERROR) {
                return uint256(err);
            }

            if (shortfall == 0) {
                return uint256(Error.INSUFFICIENT_SHORTFALL);
            }

            /* The liquidator may not repay more than what is allowed by the closeFactor */
            uint256 maxClose = mul_ScalarTruncate(
                Exp({mantissa: closeFactorMantissa}),
                borrowBalance
            );
            if (repayAmount > maxClose) {
                return uint256(Error.TOO_MUCH_REPAY);
            }
        }
        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Validates liquidateBorrow and reverts on rejection. May emit logs.
     * @param oTokenBorrowed Asset which was borrowed by the borrower
     * @param oTokenCollateral Asset which was used as collateral and will be seized
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param actualRepayAmount The amount of underlying being repaid
     */
    function liquidateBorrowVerify(
        address oTokenBorrowed,
        address oTokenCollateral,
        address liquidator,
        address borrower,
        uint256 actualRepayAmount,
        uint256 seizeTokens
    ) external {
        // Shh - currently unused
        oTokenBorrowed;
        oTokenCollateral;
        liquidator;
        borrower;
        actualRepayAmount;
        seizeTokens;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets = maxAssets;
        }
    }

    /**
     * @notice Checks if the seizing of assets should be allowed to occur
     * @param oTokenCollateral Asset which was used as collateral and will be seized
     * @param oTokenBorrowed Asset which was borrowed by the borrower
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param seizeTokens The number of collateral tokens to seize
     */
    function seizeAllowed(
        address oTokenCollateral,
        address oTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external override returns (uint256) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!seizeGuardianPaused, "seize is paused");

        // Shh - currently unused
        seizeTokens;

        if (
            !markets[oTokenCollateral].isListed ||
            !markets[oTokenBorrowed].isListed
        ) {
            return uint256(Error.MARKET_NOT_LISTED);
        }

        if (
            IOToken(oTokenCollateral).comptroller() !=
            IOToken(oTokenBorrowed).comptroller()
        ) {
            return uint256(Error.COMPTROLLER_MISMATCH);
        }

        // Keep the flywheel moving
        updateRewardSupplyIndex(oTokenCollateral);
        distributeSupplierReward(oTokenCollateral, borrower);
        distributeSupplierReward(oTokenCollateral, liquidator);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Validates seize and reverts on rejection. May emit logs.
     * @param oTokenCollateral Asset which was used as collateral and will be seized
     * @param oTokenBorrowed Asset which was borrowed by the borrower
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param seizeTokens The number of collateral tokens to seize
     */
    function seizeVerify(
        address oTokenCollateral,
        address oTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external override {
        // Shh - currently unused
        oTokenCollateral;
        oTokenBorrowed;
        liquidator;
        borrower;
        seizeTokens;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets = maxAssets;
        }
    }

    /**
     * @notice Checks if the account should be allowed to transfer tokens in the given market
     * @param oToken The market to verify the transfer against
     * @param src The account which sources the tokens
     * @param dst The account which receives the tokens
     * @param transferTokens The number of oTokens to transfer
     * @return 0 if the transfer is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function transferAllowed(
        address oToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external override returns (uint256) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!transferGuardianPaused, "transfer is paused");

        // Currently the only consideration is whether or not
        //  the src is allowed to redeem this many tokens
        uint256 allowed = redeemAllowedInternal(oToken, src, transferTokens);
        if (allowed != uint256(Error.NO_ERROR)) {
            return allowed;
        }

        // Keep the flywheel moving
        updateAndDistributeSupplierRewardsForToken(oToken, src);
        updateAndDistributeSupplierRewardsForToken(oToken, dst);
        // updateRewardSupplyIndex(oToken);
        // distributeSupplierReward(oToken, src); //todo: remove
        // distributeSupplierReward(oToken, dst);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Validates transfer and reverts on rejection. May emit logs.
     * @param oToken Asset being transferred
     * @param src The account which sources the tokens
     * @param dst The account which receives the tokens
     * @param transferTokens The number of oTokens to transfer
     */
    function transferVerify(
        address oToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external override {
        // Shh - currently unused
        oToken;
        src;
        dst;
        transferTokens;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets = maxAssets;
        }
    }

    /*** Liquidity/Liquidation Calculations ***/

    /**
     * @dev Local vars for avoiding stack-depth limits in calculating account liquidity.
     *  Note that `oTokenBalance` is the number of oTokens the account owns in the market,
     *  whereas `borrowBalance` is the amount of underlying that the account has borrowed.
     */
    struct AccountLiquidityLocalVars {
        uint256 sumCollateral;
        uint256 sumBorrowPlusEffects;
        uint256 oTokenBalance;
        uint256 borrowBalance;
        uint256 exchangeRateMantissa;
        uint256 oraclePriceMantissa;
        Exp collateralFactor;
        Exp exchangeRate;
        Exp oraclePrice;
        Exp tokensToDenom;
    }

    /**
     * @notice Determine the current account liquidity wrt collateral requirements
     * @return (possible error code (semi-opaque),
                account liquidity in excess of collateral requirements,
     *          account shortfall below collateral requirements)
     */
    function getAccountLiquidity(address account)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        (
            Error err,
            uint256 liquidity,
            uint256 shortfall
        ) = getHypotheticalAccountLiquidityInternal(account, IOToken(address(0)), 0, 0);

        return (uint256(err), liquidity, shortfall);
    }

    /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param oTokenModify The market to hypothetically redeem/borrow in
     * @param account The account to determine liquidity for
     * @param redeemTokens The number of tokens to hypothetically redeem
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @return (possible error code (semi-opaque),
                hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
    function getHypotheticalAccountLiquidity(
        address account,
        address oTokenModify,
        uint256 redeemTokens,
        uint256 borrowAmount
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        (
            Error err,
            uint256 liquidity,
            uint256 shortfall
        ) = getHypotheticalAccountLiquidityInternal(
                account,
                IOToken(oTokenModify),
                redeemTokens,
                borrowAmount
            );
        return (uint256(err), liquidity, shortfall);
    }

    /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param oTokenModify The market to hypothetically redeem/borrow in
     * @param account The account to determine liquidity for
     * @param redeemTokens The number of tokens to hypothetically redeem
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @dev Note that we calculate the exchangeRateStored for each collateral oToken using stored data,
     *  without calculating accumulated interest.
     * @return (possible error code,
                hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
    function getHypotheticalAccountLiquidityInternal(
        address account,
        IOToken oTokenModify,
        uint256 redeemTokens,
        uint256 borrowAmount
    )
        internal
        view
        returns (
            Error,
            uint256,
            uint256
        )
    {
        AccountLiquidityLocalVars memory vars; // Holds all our calculation results
        uint256 oErr;

        // For each asset the account is in
        IOToken[] memory assets = accountAssets[account];
        for (uint256 i = 0; i < assets.length; i++) {
            IOToken asset = assets[i];

            // Read the balances and exchange rate from the oToken
            (
                oErr,
                vars.oTokenBalance,
                vars.borrowBalance,
                vars.exchangeRateMantissa
            ) = asset.getAccountSnapshot(account);
            if (oErr != 0) {
                // semi-opaque error code, we assume NO_ERROR == 0 is invariant between upgrades
                return (Error.SNAPSHOT_ERROR, 0, 0);
            }
            vars.collateralFactor = Exp({
                mantissa: markets[address(asset)].collateralFactorMantissa
            });
            vars.exchangeRate = Exp({mantissa: vars.exchangeRateMantissa});

            // Get the normalized price of the asset
            vars.oraclePriceMantissa = oracle.getUnderlyingPrice(asset);
            if (vars.oraclePriceMantissa == 0) {
                return (Error.PRICE_ERROR, 0, 0);
            }
            vars.oraclePrice = Exp({mantissa: vars.oraclePriceMantissa});

            // Pre-compute a conversion factor from tokens -> ether (normalized price value)
            vars.tokensToDenom = mul_(
                mul_(vars.collateralFactor, vars.exchangeRate),
                vars.oraclePrice
            );

            // sumCollateral += tokensToDenom * oTokenBalance
            vars.sumCollateral = mul_ScalarTruncateAddUInt(
                vars.tokensToDenom,
                vars.oTokenBalance,
                vars.sumCollateral
            );

            // sumBorrowPlusEffects += oraclePrice * borrowBalance
            vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(
                vars.oraclePrice,
                vars.borrowBalance,
                vars.sumBorrowPlusEffects
            );

            // Calculate effects of interacting with oTokenModify
            if (asset == oTokenModify) {
                // redeem effect
                // sumBorrowPlusEffects += tokensToDenom * redeemTokens
                vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(
                    vars.tokensToDenom,
                    redeemTokens,
                    vars.sumBorrowPlusEffects
                );

                // borrow effect
                // sumBorrowPlusEffects += oraclePrice * borrowAmount
                vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(
                    vars.oraclePrice,
                    borrowAmount,
                    vars.sumBorrowPlusEffects
                );
            }
        }

        // These are safe, as the underflow condition is checked first
        unchecked {
            if (vars.sumCollateral > vars.sumBorrowPlusEffects) {
                return (
                    Error.NO_ERROR,
                    vars.sumCollateral - vars.sumBorrowPlusEffects,
                    0
                );
            } else {
                return (
                    Error.NO_ERROR,
                    0,
                    vars.sumBorrowPlusEffects - vars.sumCollateral
                );
            }
        }
    }

    /**
     * @notice Calculate number of tokens of collateral asset to seize given an underlying amount
     * @dev Used in liquidation (called in oToken.liquidateBorrowFresh)
     * @param oTokenBorrowed The address of the borrowed oToken
     * @param oTokenCollateral The address of the collateral oToken
     * @param actualRepayAmount The amount of oTokenBorrowed underlying to convert into oTokenCollateral tokens
     * @return (errorCode, number of oTokenCollateral tokens to be seized in a liquidation)
     */
    function liquidateCalculateSeizeTokens(
        address oTokenBorrowed,
        address oTokenCollateral,
        uint256 actualRepayAmount
    ) external view override returns (uint256, uint256) {
        /* Read oracle prices for borrowed and collateral markets */
        uint256 priceBorrowedMantissa = oracle.getUnderlyingPrice(
            IOToken(oTokenBorrowed)
        );
        uint256 priceCollateralMantissa = oracle.getUnderlyingPrice(
            IOToken(oTokenCollateral)
        );

        if (priceBorrowedMantissa == 0 || priceCollateralMantissa == 0) {
            return (uint256(Error.PRICE_ERROR), 0);
        }

        /*
         * Get the exchange rate and calculate the number of collateral tokens to seize:
         *  seizeAmount = actualRepayAmount * liquidationIncentive * priceBorrowed / priceCollateral
         *  seizeTokens = seizeAmount / exchangeRate
         *   = actualRepayAmount * (liquidationIncentive * priceBorrowed) / (priceCollateral * exchangeRate)
         */
        uint256 exchangeRateMantissa = IOToken(oTokenCollateral)
            .exchangeRateStored(); // Note: reverts on error

        Exp memory numerator = mul_(Exp({mantissa: liquidationIncentiveMantissa}), Exp({mantissa: priceBorrowedMantissa}));
        Exp memory denominator = mul_(Exp({mantissa: priceCollateralMantissa}), Exp({mantissa: exchangeRateMantissa}));
        Exp memory ratio = div_(numerator, denominator);

        uint256 seizeTokens = mul_ScalarTruncate(ratio, actualRepayAmount);

        return (uint256(Error.NO_ERROR), seizeTokens);
    }

    /*** Admin Functions ***/

    /**
     * @notice Sets a new price oracle for the comptroller
     * @dev Admin function to set a new price oracle
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setPriceOracle(PriceOracle newOracle) public returns (uint256) {
        // Check caller is admin
        if (msg.sender != admin) {
            return // TODO can be optimized
                fail(
                    Error.UNAUTHORIZED,
                    FailureInfo.SET_PRICE_ORACLE_OWNER_CHECK
                );
        }

        // Track the old oracle for the comptroller
        PriceOracle oldOracle = oracle;

        // Set comptroller's oracle to newOracle
        oracle = newOracle;

        // Emit NewPriceOracle(oldOracle, newOracle)
        emit NewPriceOracle(oldOracle, newOracle);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Sets the closeFactor used when liquidating borrows
     * @dev Admin function to set closeFactor
     * @param newCloseFactorMantissa New close factor, scaled by 1e18
     * @return uint 0=success, otherwise a failure
     */
    function _setCloseFactor(uint256 newCloseFactorMantissa)
        external
        onlyAdmin
        returns (uint256)
    {
        // Check caller is admin
        //  require(msg.sender == admin, "only admin can set close factor"); // todo remove

        uint256 oldCloseFactorMantissa = closeFactorMantissa;
        closeFactorMantissa = newCloseFactorMantissa;
        emit NewCloseFactor(oldCloseFactorMantissa, closeFactorMantissa);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Sets the collateralFactor for a market
     * @dev Admin function to set per-market collateralFactor
     * @param oToken The market to set the factor on
     * @param newCollateralFactorMantissa The new collateral factor, scaled by 1e18
     * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
     */
    function _setCollateralFactor(
        IOToken oToken,
        uint256 newCollateralFactorMantissa
    ) external returns (uint256) {
        // Check caller is admin
        if (msg.sender != admin) {
            return
                fail(
                    Error.UNAUTHORIZED,
                    FailureInfo.SET_COLLATERAL_FACTOR_OWNER_CHECK
                );
        }

        // Verify market is listed
        Market storage market = markets[address(oToken)];
        if (!market.isListed) {
            return
                fail(
                    Error.MARKET_NOT_LISTED,
                    FailureInfo.SET_COLLATERAL_FACTOR_NO_EXISTS
                );
        }

        Exp memory newCollateralFactorExp = Exp({
            mantissa: newCollateralFactorMantissa
        });

        // Check collateral factor <= 0.9
        Exp memory highLimit = Exp({mantissa: collateralFactorMaxMantissa});
        if (lessThanExp(highLimit, newCollateralFactorExp)) {
            return
                fail(
                    Error.INVALID_COLLATERAL_FACTOR,
                    FailureInfo.SET_COLLATERAL_FACTOR_VALIDATION
                );
        }

        // If collateral factor != 0, fail if price == 0
        if (
            newCollateralFactorMantissa != 0 &&
            oracle.getUnderlyingPrice(oToken) == 0
        ) {
            return
                fail(
                    Error.PRICE_ERROR,
                    FailureInfo.SET_COLLATERAL_FACTOR_WITHOUT_PRICE
                );
        }

        // Set market's collateral factor to new collateral factor, remember old value
        uint256 oldCollateralFactorMantissa = market.collateralFactorMantissa;
        market.collateralFactorMantissa = newCollateralFactorMantissa;

        // Emit event with asset, old collateral factor, and new collateral factor
        emit NewCollateralFactor(
            oToken,
            oldCollateralFactorMantissa,
            newCollateralFactorMantissa
        );

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Sets liquidationIncentive
     * @dev Admin function to set liquidationIncentive
     * @param newLiquidationIncentiveMantissa New liquidationIncentive scaled by 1e18
     * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
     */
    function _setLiquidationIncentive(uint256 newLiquidationIncentiveMantissa)
        external
        returns (uint256)
    {
        // Check caller is admin
        if (msg.sender != admin) {
            return
                fail(
                    Error.UNAUTHORIZED,
                    FailureInfo.SET_LIQUIDATION_INCENTIVE_OWNER_CHECK
                );
        }

        // Save current value for use in log
        uint256 oldLiquidationIncentiveMantissa = liquidationIncentiveMantissa;

        // Set liquidation incentive to new incentive
        liquidationIncentiveMantissa = newLiquidationIncentiveMantissa;

        // Emit event with old incentive, new incentive
        emit NewLiquidationIncentive(
            oldLiquidationIncentiveMantissa,
            newLiquidationIncentiveMantissa
        );

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Add the market to the markets mapping and set it as listed
     * @dev Admin function to set isListed and add support for the market
     * @param oToken The address of the market (token) to list
     * @return uint 0=success, otherwise a failure. (See enum Error for details)
     */
    function _supportMarket(IOToken oToken) external returns (uint256) {
        if (msg.sender != admin) {
            return
                fail(
                    Error.UNAUTHORIZED,
                    FailureInfo.SUPPORT_MARKET_OWNER_CHECK
                );
        }

        if (markets[address(oToken)].isListed) {
            return
                fail(
                    Error.MARKET_ALREADY_LISTED,
                    FailureInfo.SUPPORT_MARKET_EXISTS
                );
        }

        oToken.isOToken(); // Sanity check to make sure its really a IOToken

        // Note that isOed is not in active use anymore
        markets[address(oToken)] = Market({
            isListed: true,
            isOed: false,
            collateralFactorMantissa: 0
        });

        _addMarketInternal(address(oToken));
        _initializeMarket(address(oToken));

        emit MarketListed(oToken);

        return uint256(Error.NO_ERROR);
    }

    function _addMarketInternal(address oToken) internal {
        for (uint256 i = 0; i < allMarkets.length; i++) {
            require(allMarkets[i] != IOToken(oToken), "market already added");
        }
        allMarkets.push(IOToken(oToken));
    }


    function _initializeMarket(address oToken) internal {
        uint32 timestamp = safe32(getTimestamp());

        MarketState storage supplyState = supplyState[oToken];
        MarketState storage borrowState = borrowState[oToken];

        /*
         * Update market state indices
         */
        if (supplyState.index == 0) {
            // Initialize supply state index with default value
            supplyState.index = marketInitialIndex;
        }

        if (borrowState.index == 0) {
            // Initialize borrow state index with default value
            borrowState.index = marketInitialIndex;
        }

        /*
         * Update market state timestamps
         */
        supplyState.timestamp = borrowState.timestamp = timestamp;
    }

    /**
     * @notice Set the given borrow caps for the given oToken markets. Borrowing that brings total borrows to or above borrow cap will revert.
     * @dev Admin or borrowCapGuardian function to set the borrow caps. A borrow cap of 0 corresponds to unlimited borrowing.
     * @param oTokens The addresses of the markets (tokens) to change the borrow caps for
     * @param newBorrowCaps The new borrow cap values in underlying to be set. A value of 0 corresponds to unlimited borrowing.
     */
    function _setMarketBorrowCaps(
        IOToken[] calldata oTokens,
        uint256[] calldata newBorrowCaps
    ) external {
        require(
            msg.sender == admin || msg.sender == borrowCapGuardian,
            "only admin or borrowCapGuardian"
        );

        uint256 numMarkets = oTokens.length;
        uint256 numBorrowCaps = newBorrowCaps.length;

        require(
            numMarkets != 0 && numMarkets == numBorrowCaps,
            "invalid input"
        );

        for (uint256 i = 0; i < numMarkets; i++) {
            borrowCaps[address(oTokens[i])] = newBorrowCaps[i];
            emit NewBorrowCap(oTokens[i], newBorrowCaps[i]);
        }
    }

    /**
     * @notice Admin function to change the Borrow Cap Guardian
     * @param newBorrowCapGuardian The address of the new Borrow Cap Guardian
     */
    function _setBorrowCapGuardian(address newBorrowCapGuardian)
        external
        onlyAdmin
    {
        // Save current value for inclusion in log
        address oldBorrowCapGuardian = borrowCapGuardian;

        // Store borrowCapGuardian with value newBorrowCapGuardian
        borrowCapGuardian = newBorrowCapGuardian;

        // Emit NewBorrowCapGuardian(OldBorrowCapGuardian, NewBorrowCapGuardian)
        emit NewBorrowCapGuardian(oldBorrowCapGuardian, newBorrowCapGuardian);
    }

    /**
     * @notice Admin function to change the Pause Guardian
     * @param newPauseGuardian The address of the new Pause Guardian
     * @return uint 0=success, otherwise a failure. (See enum Error for details)
     */
    function _setPauseGuardian(address newPauseGuardian)
        public
        returns (uint256)
    {
        if (msg.sender != admin) {
            return
                fail(
                    Error.UNAUTHORIZED,
                    FailureInfo.SET_PAUSE_GUARDIAN_OWNER_CHECK
                );
        }

        // Save current value for inclusion in log
        address oldPauseGuardian = pauseGuardian;

        // Store pauseGuardian with value newPauseGuardian
        pauseGuardian = newPauseGuardian;

        // Emit NewPauseGuardian(OldPauseGuardian, NewPauseGuardian)
        emit NewPauseGuardian(oldPauseGuardian, pauseGuardian);

        return uint256(Error.NO_ERROR);
    }

    function onlyAdminOrGuardian() internal view {
        require(
            msg.sender == admin || msg.sender == pauseGuardian,
            "only pause guardian and admin"
        );
    }


    function _setMintPaused(IOToken oToken, bool state) public returns (bool) {
        require(
            markets[address(oToken)].isListed,
            "cannot pause: market not listed"
        );
        onlyAdminOrGuardian();
        require(msg.sender == admin || state, "only admin can unpause");

        guardianPaused[address(oToken)].mint = state;
        emit ActionPaused(oToken, "Mint", state);
        return state;
    }

    function _setBorrowPaused(IOToken oToken, bool state) public returns (bool) {
        require(
            markets[address(oToken)].isListed,
            "cannot pause: market not listed"
        );
        onlyAdminOrGuardian();
        require(msg.sender == admin || state, "only admin can unpause");

        guardianPaused[address(oToken)].borrow = state;
        emit ActionPaused(oToken, "Borrow", state);
        return state;
    }

    function _setTransferPaused(bool state) public returns (bool) {
        onlyAdminOrGuardian();
        require(msg.sender == admin || state, "only admin can unpause");

        transferGuardianPaused = state;
        emit ActionPaused("Transfer", state);
        return state;
    }

    function _setSeizePaused(bool state) public returns (bool) {
        onlyAdminOrGuardian();
        require(msg.sender == admin || state, "only admin can unpause");

        seizeGuardianPaused = state;
        emit ActionPaused("Seize", state);
        return state;
    }

    function _become(IUnitroller unitroller) public {
        require(
            msg.sender == unitroller.admin(),
            "only unitroller admin can _become"
        );
        require(
            unitroller._acceptImplementation() == 0,
            "change not authorized"
        );
    }

    /// @notice Delete this function after proposal 65 is executed
    function fixBadAccruals(
        address[] calldata affectedUsers,
        uint256[] calldata amounts
    ) external onlyAdmin {
        // require(msg.sender == admin, "only admin can call this function"); // Only the timelock can call this function TODO clean up
        require(
            !proposal65FixExecuted,
            "Already executed this function"
        ); // Require that this function is only called once
        require(affectedUsers.length == amounts.length, "Invalid input");

        // Loop variables
        address user;
        uint256 currentAccrual;
        uint256 amountToSubtract;
        uint256 newAccrual;

        // Iterate through all affected users
        for (uint256 i = 0; i < affectedUsers.length; ++i) {
            user = affectedUsers[i];
            currentAccrual = rewardAccrued[user];

            amountToSubtract = amounts[i];

            // The case where the user has claimed and received an incorrect amount of COMP.
            // The user has less currently accrued than the amount they incorrectly received.
            if (amountToSubtract > currentAccrual) {
                // Amount of Reward the user owes the protocol
                uint256 accountReceivable = amountToSubtract - currentAccrual; // Underflow safe since amountToSubtract > currentAccrual

                uint256 oldReceivable = rewardReceivable[user];
                uint256 newReceivable = oldReceivable + accountReceivable;

                // Accounting: record the Reward debt for the user
                rewardReceivable[user] = newReceivable;

                emit RewardReceivableUpdated(
                    user,
                    oldReceivable,
                    newReceivable
                );

                amountToSubtract = currentAccrual;
            }

            if (amountToSubtract > 0) {
                // Subtract the bad accrual amount from what they have accrued.
                // Users will keep whatever they have correctly accrued.
                rewardAccrued[user] = newAccrual = currentAccrual - amountToSubtract;

                emit RewardAccruedAdjusted(user, currentAccrual, newAccrual);
            }
        }

        proposal65FixExecuted = true; // Makes it so that this function cannot be called again
    }

    /**
     * @notice Checks caller is admin, or this contract is becoming the new implementation
     */
    function adminOrInitializing() internal view returns (bool) {
        return msg.sender == admin || msg.sender == comptrollerImplementation;
    }

    /*** Comp Distribution ***/

    /**
     * @notice Set Reward speed for a single market
     * @param oToken The market whose Reward speed to update
     * @param supplySpeed New supply-side Reward speed for market
     * @param borrowSpeed New borrow-side Reward speed for market
     */
    function setRewardSpeedInternal(
        IOToken oToken,
        uint256 supplySpeed,
        uint256 borrowSpeed
    ) internal {
        require(markets[address(oToken)].isListed, "comp market is not listed");

        if (rewardSupplySpeeds[address(oToken)] != supplySpeed) {
            // Supply speed updated so let's update supply state to ensure that
            //  1. Reward accrued properly for the old speed, and
            //  2. Reward accrued at the new speed starts after this block.
            updateRewardSupplyIndex(address(oToken));

            // Update speed and emit event
            rewardSupplySpeeds[address(oToken)] = supplySpeed;
            emit RewardSupplySpeedUpdated(oToken, supplySpeed);
        }

        if (rewardBorrowSpeeds[address(oToken)] != borrowSpeed) {
            // Borrow speed updated so let's update borrow state to ensure that
            //  1. Reward accrued properly for the old speed, and
            //  2. Reward accrued at the new speed starts after this block.
            Exp memory borrowIndex = Exp({mantissa: oToken.borrowIndex()});
            updateRewardBorrowIndex(address(oToken), borrowIndex);

            // Update speed and emit event
            rewardBorrowSpeeds[address(oToken)] = borrowSpeed;
            emit RewardBorrowSpeedUpdated(oToken, borrowSpeed);
        }
    }

    function updateAndDistributeSupplierRewardsForToken(
        address oToken,
        address account
    ) public override {
        updateRewardSupplyIndex(oToken);
        distributeSupplierReward(oToken, account);
    }

    function updateAndDistributeBorrowerRewardsForToken(
        address oToken,
        address borrower
    ) public override {
        Exp memory marketBorrowIndex = Exp({
            mantissa: IOToken(oToken).borrowIndex()
        });
        updateRewardBorrowIndex(oToken, marketBorrowIndex);
        distributeBorrowerReward(oToken, borrower, marketBorrowIndex);
    }

    /**
     * @notice Accrue Reward to the market by updating the supply index
     * @param oToken The market whose supply index to update
     * @dev Index is a cumulative sum of the Reward per oToken accrued.
     */
    function updateRewardSupplyIndex(address oToken) internal {
        MarketState storage supplyState = supplyState[oToken];
        uint256 supplySpeed = rewardSupplySpeeds[oToken];
        uint32 timestamp = safe32(
            getTimestamp()
        );
        uint256 deltaBlocks = uint256(timestamp) - uint256(supplyState.timestamp);
        if (deltaBlocks > 0) {
            if (supplySpeed > 0) {
                uint256 supplyTokens = boostManager.boostedTotalSupply(oToken);
                uint256 rewardAccrued = deltaBlocks * supplySpeed;
                Double memory ratio = supplyTokens > 0
                    ? fraction(rewardAccrued, supplyTokens)
                    : Double({mantissa: 0});
                supplyState.index = safe224(
                    add_(Double({mantissa: supplyState.index}), ratio).mantissa
                );
            } 
            supplyState.timestamp = timestamp;
        }
    }

    /**
     * @notice Accrue Reward to the market by updating the borrow index
     * @param oToken The market whose borrow index to update
     * @dev Index is a cumulative sum of the Reward per oToken accrued.
     */
    function updateRewardBorrowIndex(
        address oToken,
        Exp memory marketBorrowIndex
    ) internal {
        MarketState storage borrowState = borrowState[oToken];
        uint256 borrowSpeed = rewardBorrowSpeeds[oToken];
        uint32 timestamp = safe32(
            getTimestamp()
        );
        uint256 deltaBlocks = uint256(timestamp) - uint256(borrowState.timestamp);
        if (deltaBlocks > 0) {
            if (borrowSpeed > 0) {
                uint256 borrowAmount = div_(
                    boostManager.boostedTotalBorrows(oToken),
                    marketBorrowIndex
                );
                uint256 rewardAccrued = deltaBlocks * borrowSpeed;
                Double memory ratio = borrowAmount > 0
                    ? fraction(rewardAccrued, borrowAmount)
                    : Double({mantissa: 0});
                borrowState.index = safe224(
                    add_(Double({mantissa: borrowState.index}), ratio).mantissa
                );
            } 
            borrowState.timestamp = timestamp;
        }
    }

    /**
     * @notice Calculate Reward accrued by a supplier and possibly transfer it to them
     * @param oToken The market in which the supplier is interacting
     * @param supplier The address of the supplier to distribute Reward to
     */
    function distributeSupplierReward(address oToken, address supplier)
        internal
    {
        // TODO: Don't distribute supplier Reward if the user is not in the supplier market.
        // This check should be as gas efficient as possible as distributeSupplierReward is called in many places.
        // - We really don't want to call an external contract as that's quite expensive.

        MarketState storage supplyState = supplyState[oToken];
        uint256 supplyIndex = supplyState.index;
        uint256 supplierIndex = compSupplierIndex[oToken][supplier];

        // Update supplier's index to the current index since we are distributing accrued COMP
        compSupplierIndex[oToken][supplier] = supplyIndex;

        if (supplierIndex == 0 && supplyIndex >= marketInitialIndex) {
            // Covers the case where users supplied tokens before the market's supply state index was set.
            // Rewards the user with Reward accrued from the start of when supplier rewards were first
            // set for the market.
            supplierIndex = marketInitialIndex;
        }

        // Calculate change in the cumulative sum of the Reward per oToken accrued
        Double memory deltaIndex = Double({
            mantissa: supplyIndex - supplierIndex
        });

        uint256 supplierTokens = boostManager.boostedSupplyBalanceOf(
            oToken,
            supplier
        );

        // Calculate Reward accrued: oTokenAmount * accruedPerOToken
        uint256 supplierDelta = mul_(supplierTokens, deltaIndex);

        uint256 supplierAccrued = rewardAccrued[supplier] + supplierDelta;
        rewardAccrued[supplier] = supplierAccrued;

        emit DistributedSupplierReward(
            IOToken(oToken),
            supplier,
            supplierDelta,
            supplyIndex
        );
    }

    /**
     * @notice Calculate Reward accrued by a borrower and possibly transfer it to them
     * @dev Borrowers will not begin to accrue until after the first interaction with the protocol.
     * @param oToken The market in which the borrower is interacting
     * @param borrower The address of the borrower to distribute Reward to
     */
    function distributeBorrowerReward(
        address oToken,
        address borrower,
        Exp memory marketBorrowIndex
    ) internal {
        // TODO: Don't distribute supplier Reward if the user is not in the borrower market.
        // This check should be as gas efficient as possible as distributeBorrowerReward is called in many places.
        // - We really don't want to call an external contract as that's quite expensive.

        MarketState storage borrowState = borrowState[oToken];
        uint256 borrowIndex = borrowState.index;
        uint256 borrowerIndex = rewardBorrowerIndex[oToken][borrower];

        // Update borrowers's index to the current index since we are distributing accrued COMP
        rewardBorrowerIndex[oToken][borrower] = borrowIndex;

        if (borrowerIndex == 0 && borrowIndex >= marketInitialIndex) {
            // Covers the case where users borrowed tokens before the market's borrow state index was set.
            // Rewards the user with Reward accrued from the start of when borrower rewards were first
            // set for the market.
            borrowerIndex = marketInitialIndex;
        }

        // Calculate change in the cumulative sum of the Reward per borrowed unit accrued
        Double memory deltaIndex = Double({
            mantissa: borrowIndex - borrowerIndex
        });

        uint256 borrowerAmount = div_(
            boostManager.boostedBorrowBalanceOf(oToken, borrower),
            marketBorrowIndex
        );

        // Calculate Reward accrued: oTokenAmount * accruedPerBorrowedUnit
        uint256 borrowerDelta = mul_(borrowerAmount, deltaIndex);

        uint256 borrowerAccrued = rewardAccrued[borrower] + borrowerDelta;
        rewardAccrued[borrower] = borrowerAccrued;

        emit DistributedBorrowerReward(
            IOToken(oToken),
            borrower,
            borrowerDelta,
            borrowIndex
        );
    }

    /**
     * @notice Calculate additional accrued Reward for a contributor since last accrual
     * @param contributor The address to calculate contributor rewards for
     */
    function updateContributorRewards(address contributor) public {
        uint256 rewardSpeed = rewardContributorSpeeds[contributor];
        uint256 timestamp = getTimestamp();
        uint256 deltaBlocks = timestamp - lastContributorTimestamp[contributor];
        if (deltaBlocks > 0 && rewardSpeed > 0) {
            uint256 newAccrued = deltaBlocks * rewardSpeed;
            uint256 contributorAccrued = rewardAccrued[contributor] + newAccrued;

            rewardAccrued[contributor] = contributorAccrued;
            lastContributorTimestamp[contributor] = timestamp;
        }
    }

    /**
     * @notice Claim all the reward accrued by holder in all markets
     * @param holder The address to claim Reward for
     */

    function claimReward(address holder) public returns (uint256) {
        for (uint256 i = 0; i < allMarkets.length; i++) {
            IOToken oToken = allMarkets[i];
            require(markets[address(oToken)].isListed, "market must be listed");
            // Exp memory borrowIndex = Exp({mantissa: oToken.borrowIndex()});
            // updateRewardBorrowIndex(address(oToken), borrowIndex); // todo: rmeove
            // distributeBorrowerReward(address(oToken), holder, borrowIndex);
            updateAndDistributeBorrowerRewardsForToken(address(oToken), holder);
            // updateRewardSupplyIndex(address(oToken));
            // distributeSupplierReward(address(oToken), holder);
            updateAndDistributeSupplierRewardsForToken(address(oToken), holder);
        }
        uint256 totalReward = rewardAccrued[holder];
        rewardAccrued[holder] = grantRewardInternal(
            holder,
            totalReward
        );
        return totalReward;
    }

    /**
     * @notice Claim all the reward accrued by holder in the specified markets
     * @param holder The address to claim Reward for
     * @param oTokens The list of markets to claim Reward in
     */
    function claimRewards(address holder, IOToken[] memory oTokens) public {
        // todo: undo _
        address[] memory holders = new address[](1);
        holders[0] = holder;
        claimRewards(holders, oTokens, true, true);
    }

    /**
     * @notice Claim all reward accrued by the holders
     * @param holders The addresses to claim Reward for
     * @param oTokens The list of markets to claim Reward in
     * @param borrowers Whether or not to claim Reward earned by borrowing
     * @param suppliers Whether or not to claim Reward earned by supplying
     */
    function claimRewards(
        address[] memory holders,
        IOToken[] memory oTokens,
        bool borrowers,
        bool suppliers
    ) public {
        for (uint256 i = 0; i < oTokens.length; i++) {
            IOToken oToken = oTokens[i];
            require(markets[address(oToken)].isListed, "market must be listed");
            if (borrowers) {
                Exp memory borrowIndex = Exp({mantissa: oToken.borrowIndex()});
                updateRewardBorrowIndex(address(oToken), borrowIndex);
                for (uint256 j = 0; j < holders.length; j++) {
                    distributeBorrowerReward(
                        address(oToken),
                        holders[j],
                        borrowIndex
                    );
                }
            }
            if (suppliers) {
                updateRewardSupplyIndex(address(oToken));
                for (uint256 j = 0; j < holders.length; j++) {
                    distributeSupplierReward(address(oToken), holders[j]);
                }
            }
        }
        for (uint256 j = 0; j < holders.length; j++) {
            rewardAccrued[holders[j]] = grantRewardInternal(
                holders[j],
                rewardAccrued[holders[j]]
            );
        }
    }

    /**
     * @notice Transfer Reward to the user
     * @dev Note: If there is not enough COMP, we do not perform the transfer all.
     * @param user The address of the user to transfer Reward to
     * @param amount The amount of Reward to (possibly) transfer
     * @return The amount of Reward which was NOT transferred to the user
     */
    function grantRewardInternal(address user, uint256 amount)
        internal
        returns (uint256)
    {
        IOvix vix = IOvix(getVixAddress());
        uint256 rewardRemaining = vix.balanceOf(address(this));
        if (amount > 0 && amount <= rewardRemaining) {
            vix.transfer(user, amount);
            return 0;
        }
        return amount;
    }

    /*** Comp Distribution Admin ***/

    /**
     * @notice Transfer Reward to the recipient
     * @dev Note: If there is not enough COMP, we do not perform the transfer all.
     * @param recipient The address of the recipient to transfer Reward to
     * @param amount The amount of Reward to (possibly) transfer
     */
    function _grantReward(address recipient, uint256 amount) public {
        require(adminOrInitializing(), "only admin can grant reward");
        uint256 amountLeft = grantRewardInternal(recipient, amount);
        require(amountLeft == 0, "insufficient token for grant");
        emit VixGranted(recipient, amount);
    }

    /**
     * @notice Set Reward borrow and supply speeds for the specified markets.
     * @param oTokens The markets whose Reward speed to update.
     * @param supplySpeeds New supply-side Reward speed for the corresponding market.
     * @param borrowSpeeds New borrow-side Reward speed for the corresponding market.
     */
    function _setRewardSpeeds(
        address[] memory oTokens,
        uint256[] memory supplySpeeds,
        uint256[] memory borrowSpeeds
    ) public override {
        require(msg.sender == admin || msg.sender == rewardUpdater, "only admin can set reward speed");

        uint256 numTokens = oTokens.length;
        require(
            numTokens == supplySpeeds.length &&
                numTokens == borrowSpeeds.length,
            "Comptroller::_setCompSpeeds invalid input"
        );

        for (uint256 i = 0; i < numTokens; ++i) {
            setRewardSpeedInternal(
                IOToken(oTokens[i]),
                supplySpeeds[i],
                borrowSpeeds[i]
            );
        }
    }

    /**
     * @notice Set Reward speed for a single contributor
     * @param contributor The contributor whose Reward speed to update
     * @param rewardSpeed New Reward speed for contributor
     */
    function _setContributorRewardSpeed(
        address contributor,
        uint256 rewardSpeed
    ) public {
        require(msg.sender == admin || msg.sender == rewardUpdater, "only admin can set reward speed");

        // note that Reward speed could be set to 0 to halt liquidity rewards for a contributor
        updateContributorRewards(contributor);
        if (rewardSpeed == 0) {
            // release storage
            delete lastContributorTimestamp[contributor];
        } else {
            lastContributorTimestamp[contributor] = getTimestamp();
        }
        rewardContributorSpeeds[contributor] = rewardSpeed;

        emit ContributorRewardSpeedUpdated(contributor, rewardSpeed);
    }

    /**
     * @notice Return all of the markets
     * @dev The automatic getter may be used to access an individual market.
     * @return The list of market addresses
     */
    function getAllMarkets() public view override returns (IOToken[] memory) {
        return allMarkets;
    }

    /**
     * @notice Returns true if the given oToken market has been deprecated
     * @dev All borrows in a deprecated oToken market can be immediately liquidated
     * @param oToken The market to check if deprecated
     */
    function isDeprecated(IOToken oToken) public view returns (bool) {
        return
            markets[address(oToken)].collateralFactorMantissa == 0 &&
            guardianPaused[address(oToken)].borrow == true &&
            oToken.reserveFactorMantissa() == 1e18;
    }

    function getTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    /**
     * @notice Return the address of the Reward token
     * @return The address of COMP
     */
    function getVixAddress() public view returns (address) {
        return oAddress;
    }

    /**
     * @notice Set the Ovix token address
     */
    function setOAddress(address newOAddress) public onlyAdmin {
        oAddress = newOAddress;
    }

    /**
     * @notice Set the booster manager address
     */
    function setBoostManager(address newBoostManager) public onlyAdmin {
        boostManager = IBoostManager(newBoostManager);
    }

    function getBoostManager() external view override returns(address) {
        return address(boostManager);
    }

    function setRewardUpdater(address _rewardUpdater) public onlyAdmin {
        rewardUpdater = _rewardUpdater;
        emit RewardUpdaterModified(_rewardUpdater);
    }


    /**
     * @notice payable function needed to receive MATIC
     */
    receive() payable external {
    }
}

pragma solidity 0.8.4;

contract ComptrollerErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED,
        COMPTROLLER_MISMATCH,
        INSUFFICIENT_SHORTFALL,
        INSUFFICIENT_LIQUIDITY,
        INVALID_CLOSE_FACTOR,
        INVALID_COLLATERAL_FACTOR,
        INVALID_LIQUIDATION_INCENTIVE,
        MARKET_NOT_ENTERED, // no longer possible
        MARKET_NOT_LISTED,
        MARKET_ALREADY_LISTED,
        MATH_ERROR,
        NONZERO_BORROW_BALANCE,
        PRICE_ERROR,
        REJECTION,
        SNAPSHOT_ERROR,
        TOO_MANY_ASSETS,
        TOO_MUCH_REPAY
    }

    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK,
        EXIT_MARKET_BALANCE_OWED,
        EXIT_MARKET_REJECTION,
        SET_CLOSE_FACTOR_OWNER_CHECK,
        SET_CLOSE_FACTOR_VALIDATION,
        SET_COLLATERAL_FACTOR_OWNER_CHECK,
        SET_COLLATERAL_FACTOR_NO_EXISTS,
        SET_COLLATERAL_FACTOR_VALIDATION,
        SET_COLLATERAL_FACTOR_WITHOUT_PRICE,
        SET_IMPLEMENTATION_OWNER_CHECK,
        SET_LIQUIDATION_INCENTIVE_OWNER_CHECK,
        SET_LIQUIDATION_INCENTIVE_VALIDATION,
        SET_MAX_ASSETS_OWNER_CHECK,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_PENDING_IMPLEMENTATION_OWNER_CHECK,
        SET_PRICE_ORACLE_OWNER_CHECK,
        SUPPORT_MARKET_EXISTS,
        SUPPORT_MARKET_OWNER_CHECK,
        SET_PAUSE_GUARDIAN_OWNER_CHECK
    }

    /**
      * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
      * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
      **/
    event Failure(uint error, uint info, uint detail);

    /**
      * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
      */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }

    /**
      * @dev use this when reporting an opaque error from an upgradeable collaborator contract
      */
    function failOpaque(Error err, FailureInfo info, uint opaqueError) internal returns (uint) {
        emit Failure(uint(err), uint(info), opaqueError);

        return uint(err);
    }
}

contract TokenErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED,
        BAD_INPUT,
        COMPTROLLER_REJECTION,
        COMPTROLLER_CALCULATION_ERROR,
        INTEREST_RATE_MODEL_ERROR,
        INVALID_ACCOUNT_PAIR,
        INVALID_CLOSE_AMOUNT_REQUESTED,
        INVALID_COLLATERAL_FACTOR,
        MATH_ERROR,
        MARKET_NOT_FRESH,
        MARKET_NOT_LISTED,
        TOKEN_INSUFFICIENT_ALLOWANCE,
        TOKEN_INSUFFICIENT_BALANCE,
        TOKEN_INSUFFICIENT_CASH,
        TOKEN_TRANSFER_IN_FAILED,
        TOKEN_TRANSFER_OUT_FAILED
    }

    /*
     * Note: FailureInfo (but not Error) is kept in alphabetical order
     *       This is because FailureInfo grows significantly faster, and
     *       the order of Error has some meaning, while the order of FailureInfo
     *       is entirely arbitrary.
     */
    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        ACCRUE_INTEREST_ACCUMULATED_INTEREST_CALCULATION_FAILED,
        ACCRUE_INTEREST_BORROW_RATE_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_BORROW_INDEX_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_TOTAL_BORROWS_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_TOTAL_RESERVES_CALCULATION_FAILED,
        ACCRUE_INTEREST_SIMPLE_INTEREST_FACTOR_CALCULATION_FAILED,
        BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        BORROW_ACCRUE_INTEREST_FAILED,
        BORROW_CASH_NOT_AVAILABLE,
        BORROW_FRESHNESS_CHECK,
        BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED,
        BORROW_MARKET_NOT_LISTED,
        BORROW_COMPTROLLER_REJECTION,
        LIQUIDATE_ACCRUE_BORROW_INTEREST_FAILED,
        LIQUIDATE_ACCRUE_COLLATERAL_INTEREST_FAILED,
        LIQUIDATE_COLLATERAL_FRESHNESS_CHECK,
        LIQUIDATE_COMPTROLLER_REJECTION,
        LIQUIDATE_COMPTROLLER_CALCULATE_AMOUNT_SEIZE_FAILED,
        LIQUIDATE_CLOSE_AMOUNT_IS_UINT_MAX,
        LIQUIDATE_CLOSE_AMOUNT_IS_ZERO,
        LIQUIDATE_FRESHNESS_CHECK,
        LIQUIDATE_LIQUIDATOR_IS_BORROWER,
        LIQUIDATE_REPAY_BORROW_FRESH_FAILED,
        LIQUIDATE_SEIZE_BALANCE_INCREMENT_FAILED,
        LIQUIDATE_SEIZE_BALANCE_DECREMENT_FAILED,
        LIQUIDATE_SEIZE_COMPTROLLER_REJECTION,
        LIQUIDATE_SEIZE_LIQUIDATOR_IS_BORROWER,
        LIQUIDATE_SEIZE_TOO_MUCH,
        MINT_ACCRUE_INTEREST_FAILED,
        MINT_COMPTROLLER_REJECTION,
        MINT_EXCHANGE_CALCULATION_FAILED,
        MINT_EXCHANGE_RATE_READ_FAILED,
        MINT_FRESHNESS_CHECK,
        MINT_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED,
        MINT_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
        MINT_TRANSFER_IN_FAILED,
        MINT_TRANSFER_IN_NOT_POSSIBLE,
        REDEEM_ACCRUE_INTEREST_FAILED,
        REDEEM_COMPTROLLER_REJECTION,
        REDEEM_EXCHANGE_TOKENS_CALCULATION_FAILED,
        REDEEM_EXCHANGE_AMOUNT_CALCULATION_FAILED,
        REDEEM_EXCHANGE_RATE_READ_FAILED,
        REDEEM_FRESHNESS_CHECK,
        REDEEM_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED,
        REDEEM_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
        REDEEM_TRANSFER_OUT_NOT_POSSIBLE,
        REDUCE_RESERVES_ACCRUE_INTEREST_FAILED,
        REDUCE_RESERVES_ADMIN_CHECK,
        REDUCE_RESERVES_CASH_NOT_AVAILABLE,
        REDUCE_RESERVES_FRESH_CHECK,
        REDUCE_RESERVES_VALIDATION,
        REPAY_BEHALF_ACCRUE_INTEREST_FAILED,
        REPAY_BORROW_ACCRUE_INTEREST_FAILED,
        REPAY_BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_COMPTROLLER_REJECTION,
        REPAY_BORROW_FRESHNESS_CHECK,
        REPAY_BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_TRANSFER_IN_NOT_POSSIBLE,
        SET_COLLATERAL_FACTOR_OWNER_CHECK,
        SET_COLLATERAL_FACTOR_VALIDATION,
        SET_COMPTROLLER_OWNER_CHECK,
        SET_INTEREST_RATE_MODEL_ACCRUE_INTEREST_FAILED,
        SET_INTEREST_RATE_MODEL_FRESH_CHECK,
        SET_INTEREST_RATE_MODEL_OWNER_CHECK,
        SET_MAX_ASSETS_OWNER_CHECK,
        SET_ORACLE_MARKET_NOT_LISTED,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_RESERVE_FACTOR_ACCRUE_INTEREST_FAILED,
        SET_RESERVE_FACTOR_ADMIN_CHECK,
        SET_RESERVE_FACTOR_FRESH_CHECK,
        SET_RESERVE_FACTOR_BOUNDS_CHECK,
        TRANSFER_COMPTROLLER_REJECTION,
        TRANSFER_NOT_ALLOWED,
        TRANSFER_NOT_ENOUGH,
        TRANSFER_TOO_MUCH,
        ADD_RESERVES_ACCRUE_INTEREST_FAILED,
        ADD_RESERVES_FRESH_CHECK,
        ADD_RESERVES_TRANSFER_IN_NOT_POSSIBLE,
        SET_PROTOCOL_SEIZE_SHARE_ACCRUE_INTEREST_FAILED,
        SET_PROTOCOL_SEIZE_SHARE_OWNER_CHECK,
        SET_PROTOCOL_SEIZE_SHARE_FRESH_CHECK
    }

    /**
      * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
      * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
      **/
    event Failure(uint error, uint info, uint detail);

    /**
      * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
      */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }

    /**
      * @dev use this when reporting an opaque error from an upgradeable collaborator contract
      */
    function failOpaque(Error err, FailureInfo info, uint opaqueError) internal returns (uint) {
        emit Failure(uint(err), uint(info), opaqueError);

        return uint(err);
    }
}

pragma solidity 0.8.4;

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author 0VIX
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract ExponentialNoError {
    uint constant expScale = 1e18;
    uint constant doubleScale = 1e36;
    uint constant halfExpScale = expScale/2;
    uint constant mantissaOne = expScale;

    struct Exp {
        uint mantissa;
    }

    struct Double {
        uint mantissa;
    }

    /**
     * @dev Truncates the given exp to a whole number value.
     *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
     */
    function truncate(Exp memory exp) pure internal returns (uint) {
        // Note: We are not using careful math here as we're performing a division that cannot fail
        return exp.mantissa / expScale;
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mul_ScalarTruncate(Exp memory a, uint scalar) pure internal returns (uint) {
        return truncate(mul_(a, scalar));
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mul_ScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) pure internal returns (uint) {
        return truncate(mul_(a, scalar)) + addend;
    }

    /**
     * @dev Checks if first Exp is less than second Exp.
     */
    function lessThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa < right.mantissa;
    }

    /**
     * @dev Checks if left Exp <= right Exp.
     */
    function lessThanOrEqualExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa <= right.mantissa;
    }

    /**
     * @dev Checks if left Exp > right Exp.
     */
    function greaterThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa > right.mantissa;
    }

    /**
     * @dev returns true if Exp is exactly zero
     */
    function isZeroExp(Exp memory value) pure internal returns (bool) {
        return value.mantissa == 0;
    }

    function safe224(uint n) pure internal returns (uint224) {
        require(n < 2**224, "safe224 overflow");
        return uint224(n);
    }

    function safe32(uint n) pure internal returns (uint32) {
        require(n < 2**32, "safe32 overflow");
        return uint32(n);
    }

    function add_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: a.mantissa + b.mantissa});
    }

    function add_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: a.mantissa + b.mantissa});
    }

    function add_(uint a, uint b, string memory errorMessage) pure internal returns (uint c) {
        unchecked {
            require((c = a + b ) >= a, errorMessage);
        }
    }

    function sub_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: a.mantissa - b.mantissa});
    }

    function sub_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: a.mantissa - b.mantissa});
    }

    function sub_(uint a, uint b, string memory errorMessage) pure internal returns (uint c) {
        unchecked {
            require((c = a - b) <= a, errorMessage);
        }
    }

    function mul_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: (a.mantissa * b.mantissa) / expScale});
    }

    function mul_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: a.mantissa * b});
    }

    function mul_(uint a, Exp memory b) pure internal returns (uint) {
        return (a * b.mantissa) / expScale;
    }

    function mul_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: (a.mantissa * b.mantissa) / doubleScale});
    }

    function mul_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: a.mantissa * b});
    }

    function mul_(uint a, Double memory b) pure internal returns (uint) {
        return (a * b.mantissa) / doubleScale;
    }

    function mul_(uint a, uint b, string memory errorMessage) pure internal returns (uint c) {
        unchecked {
            require(a == 0 || (c = a * b) / a == b, errorMessage);
        }
    }

    function div_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: (a.mantissa * expScale) / b.mantissa});
    }

    function div_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: a.mantissa / b});
    }

    function div_(uint a, Exp memory b) pure internal returns (uint) {
        return (a * expScale) / b.mantissa;
    }

    function div_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: (a.mantissa * doubleScale) / b.mantissa});
    }

    function div_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: a.mantissa / b});
    }

    function div_(uint a, Double memory b) pure internal returns (uint) {
        return (a * doubleScale) / b.mantissa;
    }

    function div_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function fraction(uint a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: (a * doubleScale) / b});
    }
}

pragma solidity 0.8.4;

import "../otokens/interfaces/IOToken.sol";

interface IComptroller {
    /// @notice Indicator that this is a Comptroller contract (for inspection)
    function isComptroller() external view returns(bool);

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata oTokens) external returns (uint[] memory);
    function exitMarket(address oToken) external returns (uint);

    /*** Policy Hooks ***/

    function mintAllowed(address oToken, address minter, uint mintAmount) external returns (uint);
    function mintVerify(address oToken, address minter, uint mintAmount, uint mintTokens) external;

    function redeemAllowed(address oToken, address redeemer, uint redeemTokens) external returns (uint);
    function redeemVerify(address oToken, address redeemer, uint redeemAmount, uint redeemTokens) external;

    function borrowAllowed(address oToken, address borrower, uint borrowAmount) external returns (uint);
    function borrowVerify(address oToken, address borrower, uint borrowAmount) external;

    function repayBorrowAllowed(
        address oToken,
        address payer,
        address borrower,
        uint repayAmount) external returns (uint);

    function liquidateBorrowAllowed(
        address oTokenBorrowed,
        address oTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) external returns (uint);

    function seizeAllowed(
        address oTokenCollateral,
        address oTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external returns (uint);
        
    function seizeVerify(
        address oTokenCollateral,
        address oTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external;

    function transferAllowed(address oToken, address src, address dst, uint transferTokens) external returns (uint);
    function transferVerify(address oToken, address src, address dst, uint transferTokens) external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address oTokenBorrowed,
        address oTokenCollateral,
        uint repayAmount) external view returns (uint, uint);



    function isMarket(address market) external view returns(bool);
    function getBoostManager() external view returns(address);
    function getAllMarkets() external view returns(IOToken[] memory);

    function updateAndDistributeSupplierRewardsForToken(
        address oToken,
        address account
    ) external;

    function updateAndDistributeBorrowerRewardsForToken(
        address oToken,
        address borrower
    ) external;

    function _setRewardSpeeds(
        address[] memory oTokens,
        uint256[] memory supplySpeeds,
        uint256[] memory borrowSpeeds
    ) external;
}

pragma solidity 0.8.4;

import "./otokens/interfaces/IOToken.sol";
import "./PriceOracle.sol";
import "./vote-escrow/interfaces/IBoostManager.sol";

import "./UnitrollerAdminStorage.sol";

contract ComptrollerV1Storage is UnitrollerAdminStorage {
    /**
     * @notice Oracle which gives the price of any given asset
     */
    PriceOracle public oracle;

    /**
     * @notice Multiplier used to calculate the maximum repayAmount when liquidating a borrow
     */
    uint public closeFactorMantissa;

    /**
     * @notice Multiplier representing the discount on collateral that a liquidator receives
     */
    uint public liquidationIncentiveMantissa;

    /**
     * @notice Max number of assets a single account can participate in (borrow or use as collateral)
     */
    uint public maxAssets;

    /**
     * @notice Per-account mapping of "assets you are in", capped by maxAssets
     */
    mapping(address => IOToken[]) public accountAssets;

    /// @notice Per-market mapping of "accounts in this asset"
    mapping(address => mapping(address => bool)) public accountMembership;

}

contract ComptrollerV2Storage is ComptrollerV1Storage {
    struct Market {
        /// @notice Whether or not this market is listed
        bool isListed;

        /// @notice Whether or not this market receives COMP
        bool isOed;
        /**
         * @notice Multiplier representing the most one can borrow against their collateral in this market.
         *  For instance, 0.9 to allow borrowing 90% of collateral value.
         *  Must be between 0 and 1, and stored as a mantissa.
         */
        uint collateralFactorMantissa;
    }

    /**
     * @notice Official mapping of oTokens -> Market metadata
     * @dev Used e.g. to determine if a market is supported
     */
    mapping(address => Market) public markets;


    /**
     * @notice The Pause Guardian can pause certain actions as a safety mechanism.
     *  Actions which allow users to remove their own assets cannot be paused.
     *  Liquidation / seizing / transfer can only be paused globally, not by market.
     */
    address public pauseGuardian;
    bool public _mintGuardianPaused;
    bool public _borrowGuardianPaused;
    bool public transferGuardianPaused;
    bool public seizeGuardianPaused;
    
    struct PauseData {
        bool mint;
        bool borrow;
    }

    mapping(address => PauseData) public guardianPaused;
}

contract ComptrollerV3Storage is ComptrollerV2Storage {
    struct MarketState {
        /// @notice The market's last updated tokenBorrowIndex or tokenSupplyIndex
        uint224 index;

        /// @notice The timestamp the index was last updated at
        uint32 timestamp;
    }

    /// @notice A list of all markets
    IOToken[] public allMarkets;

    /// @notice The rate at which the flywheel distributes COMP, per second
    uint public compRate;

    /// @notice The portion of compRate that each market currently receives
    mapping(address => uint) public rewardSpeeds;

    /// @notice The COMP market supply state for each market
    mapping(address => MarketState) public supplyState;

    /// @notice The COMP market borrow state for each market
    mapping(address => MarketState) public borrowState;

    /// @notice The COMP borrow index for each market for each supplier as of the last time they accrued COMP
    mapping(address => mapping(address => uint)) public compSupplierIndex;

    /// @notice The COMP borrow index for each market for each borrower as of the last time they accrued COMP
    mapping(address => mapping(address => uint)) public rewardBorrowerIndex;

    /// @notice The COMP accrued but not yet transferred to each user
    mapping(address => uint) public rewardAccrued;
}

contract ComptrollerV4Storage is ComptrollerV3Storage {
    // @notice The borrowCapGuardian can set borrowCaps to any number for any market. Lowering the borrow cap could disable borrowing on the given market.
    address public borrowCapGuardian;

    // @notice Borrow caps enforced by borrowAllowed for each oToken address. Defaults to zero which corresponds to unlimited borrowing.
    mapping(address => uint) public borrowCaps;
}

contract ComptrollerV5Storage is ComptrollerV4Storage {
    /// @notice The portion of COMP that each contributor receives per second
    mapping(address => uint) public rewardContributorSpeeds;

    /// @notice Last timestamp at which a contributor's COMP rewards have been allocated
    mapping(address => uint) public lastContributorTimestamp;
}

contract ComptrollerV6Storage is ComptrollerV5Storage {
    /// @notice The rate at which comp is distributed to the corresponding borrow market (per second)
    mapping(address => uint) public rewardBorrowSpeeds;

    /// @notice The rate at which comp is distributed to the corresponding supply market (per second)
    mapping(address => uint) public rewardSupplySpeeds;
}

contract ComptrollerV7Storage is ComptrollerV6Storage {
    /// @notice Flag indicating whether the function to fix COMP accruals has been executed (RE: proposal 62 bug)
    bool public proposal65FixExecuted;

    /// @notice Accounting storage mapping account addresses to how much COMP they owe the protocol.
    mapping(address => uint) public rewardReceivable;

    IBoostManager public boostManager;
}

pragma solidity 0.8.4;

import "../../interfaces/IComptroller.sol";
import "../../interest-rate-models/interfaces/IInterestRateModel.sol";
import "./IEIP20NonStandard.sol";
import "./IEIP20.sol";

interface IOToken is IEIP20{
    /**
     * @notice Indicator that this is a OToken contract (for inspection)
     */
    function isOToken() external view returns(bool);


    /*** Market Events ***/

    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(uint cashPrior, uint interestAccumulated, uint borrowIndex, uint totalBorrows);

    /**
     * @notice Event emitted when tokens are minted
     */
    event Mint(address minter, uint mintAmount, uint mintTokens);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint redeemAmount, uint redeemTokens);

    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(address borrower, uint borrowAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(address payer, address borrower, uint repayAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(address liquidator, address borrower, uint repayAmount, address oTokenCollateral, uint seizeTokens);


    /*** Admin Events ***/

    /**
     * @notice Event emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @notice Event emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    /**
     * @notice Event emitted when comptroller is changed
     */
    event NewComptroller(IComptroller oldComptroller, IComptroller newComptroller);

    /**
     * @notice Event emitted when interestRateModel is changed
     */
    event NewMarketInterestRateModel(IInterestRateModel oldInterestRateModel, IInterestRateModel newInterestRateModel);

    /**
     * @notice Event emitted when the reserve factor is changed
     */
    event NewReserveFactor(uint oldReserveFactorMantissa, uint newReserveFactorMantissa);

    /**
     * @notice Event emitted when the protocol seize share is changed
     */
    event NewProtocolSeizeShare(uint oldProtocolSeizeShareMantissa, uint newProtocolSeizeShareMantissa);

    /**
     * @notice Event emitted when the reserves are added
     */
    event ReservesAdded(address benefactor, uint addAmount, uint newTotalReserves);

    /**
     * @notice Event emitted when the reserves are reduced
     */
    event ReservesReduced(address admin, uint reduceAmount, uint newTotalReserves);

    function accrualBlockTimestamp() external returns(uint256);

    /*** User Interface ***/

    function balanceOfUnderlying(address owner) external returns (uint);
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
    function borrowRatePerTimestamp() external view returns (uint);
    function supplyRatePerTimestamp() external view returns (uint);
    function totalBorrowsCurrent() external returns (uint);
    function borrowBalanceCurrent(address account) external returns (uint);
    function borrowBalanceStored(address account) external view returns (uint);
    function exchangeRateCurrent() external returns (uint);
    function exchangeRateStored() external view returns (uint);
    function getCash() external view returns (uint);
    function accrueInterest() external returns (uint);
    function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint);

    function totalBorrows() external view returns(uint);
    function comptroller() external view returns(IComptroller);
    function borrowIndex() external view returns(uint);
    function reserveFactorMantissa() external view returns(uint);


    /*** Admin Functions ***/

    function _setPendingAdmin(address payable newPendingAdmin) external returns (uint);
    function _acceptAdmin() external returns (uint);
    function _setComptroller(IComptroller newComptroller) external returns (uint);
    function _setReserveFactor(uint newReserveFactorMantissa) external returns (uint);
    function _reduceReserves(uint reduceAmount) external returns (uint);
    function _setInterestRateModel(IInterestRateModel newInterestRateModel) external returns (uint);
    function _setProtocolSeizeShare(uint newProtocolSeizeShareMantissa) external returns (uint);
}

pragma solidity 0.8.4;

/**
  * @title 0VIX's IInterestRateModel Interface
  * @author 0VIX
  */
interface IInterestRateModel {
    /// @notice Indicator that this is an InterestRateModel contract (for inspection)
    function isInterestRateModel() external view returns(bool);

    /**
      * @notice Calculates the current borrow interest rate per timestmp
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @return The borrow rate per timestmp (as a percentage, and scaled by 1e18)
      */
    function getBorrowRate(uint cash, uint borrows, uint reserves) external view returns (uint);

    /**
      * @notice Calculates the current supply interest rate per timestmp
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @param reserveFactorMantissa The current reserve factor the market has
      * @return The supply rate per timestmp (as a percentage, and scaled by 1e18)
      */
    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) external view returns (uint);

}

pragma solidity 0.8.4;

/**
 * @title IEIP20NonStandard
 * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
interface IEIP20NonStandard {

    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return balance The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transfer(address dst, uint256 amount) external;

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transferFrom(address src, address dst, uint256 amount) external;

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved
      * @return success Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return remaining The number of tokens allowed to be spent
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

pragma solidity 0.8.4;

/**
 * @title ERC 20 Token Standard Interface
 *  https://eips.ethereum.org/EIPS/eip-20
 */
interface IEIP20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    /**
      * @notice Get the total number of tokens in circulation
      * @return The supply of tokens
      */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return balance The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return success Whether or not the transfer succeeded
      */
    function transfer(address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return success Whether or not the transfer succeeded
      */
    function transferFrom(address src, address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved (-1 means infinite)
      * @return success Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return remaining The number of tokens allowed to be spent (-1 means infinite)
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

pragma solidity 0.8.4;

import "./otokens/interfaces/IOToken.sol";

abstract contract PriceOracle {
    /// @notice Indicator that this is a PriceOracle contract (for inspection)
    bool public constant isPriceOracle = true;

    /**
      * @notice Get the underlying price of a oToken asset
      * @param oToken The oToken to get the underlying price of
      * @return The underlying asset price mantissa (scaled by 1e18).
      *  Zero means the price is unavailable.
      */
    function getUnderlyingPrice(IOToken oToken) external virtual view returns (uint);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBoostManager {
    function updateBoostBasis(address user)
        external
        returns (bool);

    function updateBoostSupplyBalances(
        address market,
        address user,
        uint256 oldBalance,
        uint256 newBalance
    ) external;

    function updateBoostBorrowBalances(
        address market,
        address user,
        uint256 oldBalance,
        uint256 newBalance
    ) external;

    function boostedSupplyBalanceOf(address market, address user)
        external
        view
        returns (uint256);

    function boostedBorrowBalanceOf(address market, address user)
        external
        view
        returns (uint256);

    function boostedTotalSupply(address market) external view returns (uint256);

    function boostedTotalBorrows(address market)
        external
        view
        returns (uint256);

    function setAuthorized(address addr, bool flag) external;

    function setVeOVIX(IERC20 ve) external;

    function isAuthorized(address addr) external view returns (bool);
}

pragma solidity 0.8.4;

abstract contract UnitrollerAdminStorage {
    /**
    * @notice Administrator for this contract
    */
    address public admin;

    /**
    * @notice Pending administrator for this contract
    */
    address public pendingAdmin;

    /**
    * @notice Active brains of Unitroller
    */
    address public comptrollerImplementation;

    /**
    * @notice Pending brains of Unitroller
    */
    address public pendingComptrollerImplementation;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}