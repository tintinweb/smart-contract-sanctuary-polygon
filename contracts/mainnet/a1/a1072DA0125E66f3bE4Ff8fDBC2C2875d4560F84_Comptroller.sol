pragma solidity 0.5.16;

import "./CToken.sol";
import "./CErc20.sol";
import "./ErrorReporter.sol";
import "./Exponential.sol";
import "./PriceOracle.sol";
import "./ComptrollerInterface.sol";
import "./ComptrollerStorage.sol";
import "./IUniV3LpVault.sol";

/**
 * @title Compound's Comptroller Contract
 * @author Compound
 * @dev This contract should not to be deployed alone; instead, deploy `Unitroller` (proxy contract) on top of this `Comptroller` (logic/implementation contract).
 */
contract Comptroller is ComptrollerV3Storage, ComptrollerInterface, ComptrollerErrorReporter, Exponential {
    /// @notice Emitted when an admin supports a market
    event MarketListed(CToken cToken);

    /// @notice Emitted when an admin unsupports a market
    event MarketUnlisted(CToken cToken);

    /// @notice Emitted when an account enters a market
    event MarketEntered(CToken cToken, address account);

    /// @notice Emitted when an account exits a market
    event MarketExited(CToken cToken, address account);

    /// @notice Emitted when close factor is changed by admin
    event NewCloseFactor(uint256 oldCloseFactorMantissa, uint256 newCloseFactorMantissa);

    /// @notice Emitted when a collateral factor is changed by admin
    event NewCollateralFactor(CToken cToken, uint256 oldCollateralFactorMantissa, uint256 newCollateralFactorMantissa);

    /// @notice Emitted when a pool's collateral factor is changed by admin
    event NewPoolCollateralFactor(
        address pool,
        uint256 oldCollateralFactorMantissa,
        uint256 newCollateralFactorMantissa
    );

    /// @notice Emitted when liquidation incentive is changed by admin
    event NewLiquidationIncentive(uint256 oldLiquidationIncentiveMantissa, uint256 newLiquidationIncentiveMantissa);

    /// @notice Emitted when liquidation incentive is changed by admin
    event NewLiquidationIncentiveUniV3(
        uint256 oldLiquidationIncentiveMantissa,
        uint256 newLiquidationIncentiveMantissa
    );

    /// @notice Emitted when price oracle is changed
    event NewPriceOracle(PriceOracle oldPriceOracle, PriceOracle newPriceOracle);

    /// @notice Emitted when tick oracle is changed
    event NewTickOracle(IChainlinkTickOracle oldTickOracle, IChainlinkTickOracle newTickOracle);

    /// @notice Emitted when UniV3LpVault is changed
    event NewUniV3LpVault(IUniV3LpVault oldVault, IUniV3LpVault newVault);

    /// @notice Emitted when pause guardian is changed
    event NewPauseGuardian(address oldPauseGuardian, address newPauseGuardian);

    /// @notice Emitted when an action is paused globally
    event ActionPaused(string action, bool pauseState);

    /// @notice Emitted when an action is paused on a market
    event ActionPausedMarket(CToken cToken, string action, bool pauseState);

    /// @notice Emitted when supply cap for a cToken is changed
    event NewSupplyCap(CToken indexed cToken, uint256 newSupplyCap);

    /// @notice Emitted when borrow cap for a cToken is changed
    event NewBorrowCap(CToken indexed cToken, uint256 newBorrowCap);

    /// @notice Emitted when borrow cap guardian is changed
    event NewBorrowCapGuardian(address oldBorrowCapGuardian, address newBorrowCapGuardian);

    /// @notice Emitted when pendingAdmin is changed
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /// @notice Emitted when pendingAdmin is accepted, which means admin is updated
    event NewAdmin(address oldAdmin, address newAdmin);

    // closeFactorMantissa must be strictly greater than this value
    uint256 internal constant closeFactorMinMantissa = 0.05e18; // 0.05

    // closeFactorMantissa must not exceed this value
    uint256 internal constant closeFactorMaxMantissa = 0.9e18; // 0.9

    // No collateralFactorMantissa may exceed this value
    uint256 internal constant collateralFactorMaxMantissa = 0.9e18; // 0.9

    // liquidationIncentiveMantissa must be no less than this value
    uint256 internal constant liquidationIncentiveMinMantissa = 1.0e18; // 1.0

    // liquidationIncentiveMantissa must be no greater than this value
    uint256 internal constant liquidationIncentiveMaxMantissa = 1.5e18; // 1.5

    constructor(address _admin) public {
        admin = _admin;
        _notEntered = true;
        _notEnteredInitialized = true;
    }

    /*** Assets You Are In ***/

    /**
     * @notice Returns the assets an account has entered
     * @param account The address of the account to pull assets for
     * @return A dynamic list with the assets the account has entered
     */
    function getAssetsIn(address account) external view returns (CToken[] memory) {
        CToken[] memory assetsIn = accountAssets[account];

        return assetsIn;
    }

    /**
     * @notice Returns whether the given account is entered in the given asset
     * @param account The address of the account to check
     * @param cToken The cToken to check
     * @return True if the account is in the asset, otherwise false.
     */
    function checkMembership(address account, CToken cToken) external view returns (bool) {
        return markets[address(cToken)].accountMembership[account];
    }

    /**
     * @notice Add assets to be included in account liquidity calculation
     * @param cTokens The list of addresses of the cToken markets to be enabled
     * @return Success indicator for whether each corresponding market was entered
     */
    function enterMarkets(address[] memory cTokens) public returns (uint256[] memory) {
        uint256 len = cTokens.length;

        uint256[] memory results = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            CToken cToken = CToken(cTokens[i]);

            results[i] = uint256(addToMarketInternal(cToken, msg.sender));
        }

        return results;
    }

    /**
     * @notice Add the market to the borrower's "assets in" for liquidity calculations
     * @param cToken The market to enter
     * @param borrower The address of the account to modify
     * @return Success indicator for whether the market was entered
     */
    function addToMarketInternal(CToken cToken, address borrower) internal returns (Error) {
        Market storage marketToJoin = markets[address(cToken)];

        if (!marketToJoin.isListed) {
            // market is not listed, cannot join
            return Error.MARKET_NOT_LISTED;
        }

        if (marketToJoin.accountMembership[borrower] == true) {
            // already joined
            return Error.NO_ERROR;
        }

        // survived the gauntlet, add to list
        // NOTE: we store these somewhat redundantly as a significant optimization
        //  this avoids having to iterate through the list for the most common use cases
        //  that is, only when we need to perform liquidity checks
        //  and not whenever we want to check if an account is in a particular market
        marketToJoin.accountMembership[borrower] = true;
        accountAssets[borrower].push(cToken);

        // Add to allBorrowers
        if (!borrowers[borrower]) {
            allBorrowers.push(borrower);
            borrowers[borrower] = true;
            borrowerIndexes[borrower] = allBorrowers.length - 1;
        }

        emit MarketEntered(cToken, borrower);

        return Error.NO_ERROR;
    }

    /**
     * @notice Removes asset from sender's account liquidity calculation
     * @dev Sender must not have an outstanding borrow balance in the asset,
     *  or be providing neccessary collateral for an outstanding borrow.
     * @param cTokenAddress The address of the asset to be removed
     * @return Whether or not the account successfully exited the market
     */
    function exitMarket(address cTokenAddress) external returns (uint256) {
        CToken cToken = CToken(cTokenAddress);
        /* Get sender tokensHeld and amountOwed underlying from the cToken */
        (uint256 oErr, uint256 tokensHeld, uint256 amountOwed, ) = cToken.getAccountSnapshot(msg.sender);
        require(oErr == 0, "exitMarket: getAccountSnapshot failed"); // semi-opaque error code

        /* Fail if the sender has a borrow balance */
        if (amountOwed != 0) {
            return fail(Error.NONZERO_BORROW_BALANCE, FailureInfo.EXIT_MARKET_BALANCE_OWED);
        }

        /* Fail if the sender is not permitted to redeem all of their tokens */
        uint256 allowed = redeemAllowedInternal(cTokenAddress, msg.sender, tokensHeld);
        if (allowed != 0) {
            return failOpaque(Error.REJECTION, FailureInfo.EXIT_MARKET_REJECTION, allowed);
        }

        Market storage marketToExit = markets[address(cToken)];

        /* Return true if the sender is not already ‘in’ the market */
        if (!marketToExit.accountMembership[msg.sender]) {
            return uint256(Error.NO_ERROR);
        }

        /* Set cToken account membership to false */
        delete marketToExit.accountMembership[msg.sender];

        /* Delete cToken from the account’s list of assets */
        // load into memory for faster iteration
        CToken[] memory userAssetList = accountAssets[msg.sender];
        uint256 len = userAssetList.length;
        uint256 assetIndex = len;
        for (uint256 i = 0; i < len; i++) {
            if (userAssetList[i] == cToken) {
                assetIndex = i;
                break;
            }
        }

        // We *must* have found the asset in the list or our redundant data structure is broken
        assert(assetIndex < len);

        // copy last item in list to location of item to be removed, reduce length by 1
        CToken[] storage storedList = accountAssets[msg.sender];
        storedList[assetIndex] = storedList[storedList.length - 1];
        storedList.length--;

        // If the user has exited all markets, remove them from the `allBorrowers` array
        if (storedList.length == 0) {
            allBorrowers[borrowerIndexes[msg.sender]] = allBorrowers[allBorrowers.length - 1]; // Copy last item in list to location of item to be removed
            allBorrowers.length--; // Reduce length by 1
            borrowerIndexes[allBorrowers[borrowerIndexes[msg.sender]]] = borrowerIndexes[msg.sender]; // Set borrower index of moved item to correct index
            borrowerIndexes[msg.sender] = 0; // Reset sender borrower index to 0 for a gas refund
            borrowers[msg.sender] = false; // Tell the contract that the sender is no longer a borrower (so it knows to add the borrower back if they enter a market in the future)
        }

        emit MarketExited(cToken, msg.sender);

        return uint256(Error.NO_ERROR);
    }

    /*** Policy Hooks ***/

    /**
     * @notice Checks if the account should be allowed to mint tokens in the given market
     * @param cToken The market to verify the mint against
     * @param minter The account which would get the minted tokens
     * @param mintAmount The amount of underlying being supplied to the market in exchange for tokens
     * @return 0 if the mint is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function mintAllowed(
        address cToken,
        address minter,
        uint256 mintAmount
    ) external returns (uint256) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!mintGuardianPaused[cToken], "mint is paused");

        // Shh - currently unused
        minter;
        mintAmount;

        // Make sure market is listed
        if (!markets[cToken].isListed) {
            return uint256(Error.MARKET_NOT_LISTED);
        }

        // deposits are automatically treated as collateral
        if (!markets[cToken].accountMembership[minter]) {
            // only cTokens may call mintAllowed if minter not in market
            require(msg.sender == cToken, "sender must be cToken");

            // attempt to add minter to the market
            Error err = addToMarketInternal(CToken(msg.sender), minter);
            if (err != Error.NO_ERROR) {
                return uint256(err);
            }

            // it should be impossible to break the important invariant
            assert(markets[cToken].accountMembership[minter]);
        }

        // Check supply cap
        uint256 supplyCap = supplyCaps[cToken];
        // Supply cap of 0 corresponds to unlimited supplying
        if (supplyCap != 0) {
            uint256 totalCash = CToken(cToken).getCash();
            uint256 totalBorrows = CToken(cToken).totalBorrows();
            uint256 totalReserves = CToken(cToken).totalReserves();

            // totalUnderlyingSupply = totalCash + totalBorrows - (totalReserves)
            (MathError mathErr, uint256 totalUnderlyingSupply) = addThenSubUInt(totalCash, totalBorrows, totalReserves);
            if (mathErr != MathError.NO_ERROR) return uint256(Error.MATH_ERROR);

            uint256 nextTotalUnderlyingSupply;
            (mathErr, nextTotalUnderlyingSupply) = addUInt(totalUnderlyingSupply, mintAmount);
            if (mathErr != MathError.NO_ERROR) return uint256(Error.MATH_ERROR);

            require(nextTotalUnderlyingSupply < supplyCap, "market supply cap reached");
        }

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Checks if the account should be allowed to redeem tokens in the given market
     * @param cToken The market to verify the redeem against
     * @param redeemer The account which would redeem the tokens
     * @param redeemTokens The number of cTokens to exchange for the underlying asset in the market
     * @return 0 if the redeem is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function redeemAllowed(
        address cToken,
        address redeemer,
        uint256 redeemTokens
    ) external returns (uint256) {
        uint256 allowed = redeemAllowedInternal(cToken, redeemer, redeemTokens);
        if (allowed != uint256(Error.NO_ERROR)) {
            return allowed;
        }

        return uint256(Error.NO_ERROR);
    }

    function redeemAllowedInternal(
        address cToken,
        address redeemer,
        uint256 redeemTokens
    ) internal view returns (uint256) {
        if (!markets[cToken].isListed) {
            return uint256(Error.MARKET_NOT_LISTED);
        }

        /* If the redeemer is not 'in' the market, then we can bypass the liquidity check */
        if (!markets[cToken].accountMembership[redeemer]) {
            return uint256(Error.NO_ERROR);
        }

        /* Otherwise, perform a hypothetical liquidity check to guard against shortfall */
        (Error err, , uint256 shortfall) = getHypotheticalAccountLiquidityInternal(
            redeemer,
            CToken(cToken),
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
     * @param cToken Asset being redeemed
     * @param redeemer The address redeeming the tokens
     * @param redeemAmount The amount of the underlying asset being redeemed
     * @param redeemTokens The number of tokens being redeemed
     */
    function redeemVerify(
        address cToken,
        address redeemer,
        uint256 redeemAmount,
        uint256 redeemTokens
    ) external {
        // Shh - currently unused
        cToken;
        redeemer;

        // Require tokens is zero or amount is also zero
        if (redeemTokens == 0 && redeemAmount > 0) {
            revert("redeemTokens zero");
        }
    }

    /**
     * @notice Checks if the account should be allowed to borrow the underlying asset of the given market
     * @param cToken The market to verify the borrow against
     * @param borrower The account which would borrow the asset
     * @param borrowAmount The amount of underlying the account would borrow
     * @return 0 if the borrow is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function borrowAllowed(
        address cToken,
        address borrower,
        uint256 borrowAmount
    ) external returns (uint256) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!borrowGuardianPaused[cToken], "borrow is paused");

        // Make sure market is listed
        if (!markets[cToken].isListed) {
            return uint256(Error.MARKET_NOT_LISTED);
        }

        if (!markets[cToken].accountMembership[borrower]) {
            // only cTokens may call borrowAllowed if borrower not in market
            require(msg.sender == cToken, "sender must be cToken");

            // attempt to add borrower to the market
            Error err = addToMarketInternal(CToken(msg.sender), borrower);
            if (err != Error.NO_ERROR) {
                return uint256(err);
            }

            // it should be impossible to break the important invariant
            assert(markets[cToken].accountMembership[borrower]);
        }

        // Make sure oracle price is available
        if (oracle.getUnderlyingPrice(CToken(cToken)) == 0) {
            return uint256(Error.PRICE_ERROR);
        }

        // Check borrow cap
        uint256 borrowCap = borrowCaps[cToken];
        // Borrow cap of 0 corresponds to unlimited borrowing
        if (borrowCap != 0) {
            uint256 totalBorrows = CToken(cToken).totalBorrows();
            (MathError mathErr, uint256 nextTotalBorrows) = addUInt(totalBorrows, borrowAmount);
            if (mathErr != MathError.NO_ERROR) return uint256(Error.MATH_ERROR);
            require(nextTotalBorrows < borrowCap, "market borrow cap reached");
        }

        // Perform a hypothetical liquidity check to guard against shortfall
        (Error err, , uint256 shortfall) = getHypotheticalAccountLiquidityInternal(
            borrower,
            CToken(cToken),
            0,
            borrowAmount
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
     * @notice Checks if the account should be allowed to repay a borrow in the given market
     * @param cToken The market to verify the repay against
     * @param payer The account which would repay the asset
     * @param borrower The account which would borrowed the asset
     * @param repayAmount The amount of the underlying asset the account would repay
     * @return 0 if the repay is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256) {
        // Shh - currently unused
        payer;
        borrower;
        repayAmount;

        // Make sure market is listed
        if (!markets[cToken].isListed) {
            return uint256(Error.MARKET_NOT_LISTED);
        }

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Checks if the liquidation should be allowed to occur
     * @param cTokenBorrowed Asset which was borrowed by the borrower
     * @param cTokenCollateral Asset which was used as collateral and will be seized
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param repayAmount The amount of underlying being repaid
     */
    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256) {
        // Shh - currently unused
        liquidator;

        // Make sure markets are listed
        if (!markets[cTokenBorrowed].isListed || !markets[cTokenCollateral].isListed) {
            return uint256(Error.MARKET_NOT_LISTED);
        }

        // Get borrowers's underlying borrow balance
        uint256 borrowBalance = CToken(cTokenBorrowed).borrowBalanceStored(borrower);

        /* allow accounts to be liquidated if the market is deprecated */
        if (isDeprecated(CToken(cTokenBorrowed))) {
            require(borrowBalance >= repayAmount, "Can not repay more than the total borrow");
        } else {
            /* The borrower must have shortfall in order to be liquidatable */
            (Error err, , uint256 shortfall) = getAccountLiquidityInternal(borrower);
            if (err != Error.NO_ERROR) {
                return uint256(err);
            }

            if (shortfall == 0) {
                return uint256(Error.INSUFFICIENT_SHORTFALL);
            }

            /* The liquidator may not repay more than what is allowed by the closeFactor */
            uint256 maxClose = mul_ScalarTruncate(Exp({ mantissa: closeFactorMantissa }), borrowBalance);
            if (repayAmount > maxClose) {
                return uint256(Error.TOO_MUCH_REPAY);
            }
        }

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Checks if the liquidation should be allowed to occur
     * @param cTokenBorrowed Asset which was borrowed by the borrower
     * @param collateralTokenId the tokenId of the Uni V3 NFT being used as collateral
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param repayAmount The amount of underlying being repaid
     */
    function liquidateBorrowUniV3Allowed(
        address cTokenBorrowed,
        uint256 collateralTokenId,
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256) {
        // Shh - currently unused
        collateralTokenId;
        liquidator;

        if (!markets[cTokenBorrowed].isListed) {
            return uint256(Error.MARKET_NOT_LISTED);
        }

        if (uniV3LpVault.ownerOf(collateralTokenId) != borrower) {
            return uint256(Error.TOKEN_ID_BORROWER_MISMATCH);
        }

        uint256 borrowBalance = CToken(cTokenBorrowed).borrowBalanceStored(borrower);

        /* allow accounts to be liquidated if the market is deprecated */
        if (isDeprecated(CToken(cTokenBorrowed))) {
            require(borrowBalance >= repayAmount, "Can not repay more than the total borrow");
        } else {
            /* The borrower must have shortfall in order to be liquidatable */
            (Error err, , uint256 shortfall) = getAccountLiquidityInternal(borrower);
            if (err != Error.NO_ERROR) {
                return uint256(err);
            }

            if (shortfall == 0) {
                return uint256(Error.INSUFFICIENT_SHORTFALL);
            }

            /* The liquidator may not repay more than what is allowed by the closeFactor */
            uint256 maxClose = mul_ScalarTruncate(Exp({ mantissa: closeFactorMantissa }), borrowBalance);
            if (repayAmount > maxClose) {
                return uint256(Error.TOO_MUCH_REPAY);
            }
        }
        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Checks if the seizing of assets should be allowed to occur
     * @param cTokenCollateral Asset which was used as collateral and will be seized
     * @param cTokenBorrowed Asset which was borrowed by the borrower
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param seizeTokens The number of collateral tokens to seize
     */
    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!seizeGuardianPaused, "seize is paused");

        // Shh - currently unused
        liquidator;
        borrower;
        seizeTokens;

        // Make sure markets are listed
        if (!markets[cTokenCollateral].isListed || !markets[cTokenBorrowed].isListed) {
            return uint256(Error.MARKET_NOT_LISTED);
        }

        // Make sure cToken Comptrollers are identical
        if (CToken(cTokenCollateral).comptroller() != CToken(cTokenBorrowed).comptroller()) {
            return uint256(Error.COMPTROLLER_MISMATCH);
        }

        return uint256(Error.NO_ERROR);
    }

    /**
     * new seize function for Uni V3 vault
     */
    function seizeAllowedUniV3(
        address lpVault,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 tokenId,
        uint256 seizeFeesToken0,
        uint256 seizeFeesToken1,
        uint256 seizeLiquidity
    ) external returns (uint256) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!seizeGuardianPaused, "seize is paused");

        // Shh - currently unused
        tokenId;
        seizeFeesToken0;
        seizeFeesToken1;
        seizeLiquidity;

        // check that the borrow token is listed in comptroller market
        if (!markets[cTokenBorrowed].isListed) {
            return uint256(Error.MARKET_NOT_LISTED);
        }

        // check that lpVault matches our LPVault
        if (lpVault != address(uniV3LpVault)) {
            return uint256(Error.LP_VAULT_MISMATCH);
        }

        // check that lpVault comptroller matches this comptroller
        if (uniV3LpVault.comptroller() != CToken(cTokenBorrowed).comptroller()) {
            return uint256(Error.COMPTROLLER_MISMATCH);
        }

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Checks if the account should be allowed to transfer tokens in the given market
     * @param cToken The market to verify the transfer against
     * @param src The account which sources the tokens
     * @param dst The account which receives the tokens
     * @param transferTokens The number of cTokens to transfer
     * @return 0 if the transfer is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function transferAllowed(
        address cToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external returns (uint256) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!transferGuardianPaused, "transfer is paused");

        // Currently the only consideration is whether or not
        //  the src is allowed to redeem this many tokens
        uint256 allowed = redeemAllowedInternal(cToken, src, transferTokens);
        if (allowed != uint256(Error.NO_ERROR)) {
            return allowed;
        }

        return uint256(Error.NO_ERROR);
    }

    /*** Liquidity/Liquidation Calculations ***/

    /**
     * @dev Local vars for avoiding stack-depth limits in calculating account liquidity.
     *  Note that `cTokenBalance` is the number of cTokens the account owns in the market,
     *  whereas `borrowBalance` is the amount of underlying that the account has borrowed.
     */
    struct AccountLiquidityLocalVars {
        uint256 sumCollateral;
        uint256 sumBorrowPlusEffects;
        uint256 cTokenBalance;
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
        (Error err, uint256 liquidity, uint256 shortfall) = getHypotheticalAccountLiquidityInternal(
            account,
            CToken(0),
            0,
            0
        );

        return (uint256(err), liquidity, shortfall);
    }

    /**
     * @notice Determine the current account liquidity wrt collateral requirements
     * @return (possible error code,
                account liquidity in excess of collateral requirements,
     *          account shortfall below collateral requirements)
     */
    function getAccountLiquidityInternal(address account)
        internal
        view
        returns (
            Error,
            uint256,
            uint256
        )
    {
        return getHypotheticalAccountLiquidityInternal(account, CToken(0), 0, 0);
    }

    /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param cTokenModify The market to hypothetically redeem/borrow in
     * @param account The account to determine liquidity for
     * @param redeemTokens The number of tokens to hypothetically redeem
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @return (possible error code (semi-opaque),
                hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
    function getHypotheticalAccountLiquidity(
        address account,
        address cTokenModify,
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
        (Error err, uint256 liquidity, uint256 shortfall) = getHypotheticalAccountLiquidityInternal(
            account,
            CToken(cTokenModify),
            redeemTokens,
            borrowAmount
        );
        return (uint256(err), liquidity, shortfall);
    }

    function addNFTCollateral(address account, AccountLiquidityLocalVars memory vars) internal view {
        uint256 userTokensLength = uniV3LpVault.getUserTokensLength(account);
        for (uint256 i = 0; i < userTokensLength; i++) {
            uint256 tokenId = uniV3LpVault.userTokens(account, i);

            uint256 amountToken0Fees;
            uint256 amountToken1Fees;
            uint256 amountToken0Liquidity;
            uint256 amountToken1Liquidity;
            uint256 oraclePriceMantissa0;
            uint256 oraclePriceMantissa1;
            {
                (address token0, address token1) = tickOracle.getTokens(tokenId);
                oraclePriceMantissa0 = oracle.getUnderlyingPrice(cTokensByUnderlying[token0]);
                oraclePriceMantissa1 = oracle.getUnderlyingPrice(cTokensByUnderlying[token1]);
                (amountToken0Fees, amountToken1Fees, amountToken0Liquidity, amountToken1Liquidity, ) = tickOracle
                    .getTokenBreakdownChainlink(tokenId, oraclePriceMantissa0, oraclePriceMantissa1);
            }

            {
                // avoid stack too deep
                address poolAddress = tickOracle.getPoolAddress(tokenId);
                uint256 collateralFactorMantissa = poolCollateralFactors[poolAddress];

                vars.collateralFactor = Exp({ mantissa: collateralFactorMantissa });
            }

            vars.oraclePriceMantissa = oraclePriceMantissa0;
            vars.oraclePrice = Exp({ mantissa: vars.oraclePriceMantissa });
            vars.tokensToDenom = mul_(vars.collateralFactor, vars.oraclePrice);

            vars.sumCollateral = mul_ScalarTruncateAddUInt(
                vars.tokensToDenom,
                add_(amountToken0Fees, amountToken0Liquidity),
                vars.sumCollateral
            );

            vars.oraclePriceMantissa = oraclePriceMantissa1;
            vars.oraclePrice = Exp({ mantissa: vars.oraclePriceMantissa });
            vars.tokensToDenom = mul_(vars.collateralFactor, vars.oraclePrice);

            vars.sumCollateral = mul_ScalarTruncateAddUInt(
                vars.tokensToDenom,
                add_(amountToken1Fees, amountToken1Liquidity),
                vars.sumCollateral
            );
        }
    }

    /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param cTokenModify The market to hypothetically redeem/borrow in
     * @param account The account to determine liquidity for
     * @param redeemTokens The number of tokens to hypothetically redeem
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @dev Note that we calculate the exchangeRateStored for each collateral cToken using stored data,
     *  without calculating accumulated interest.
     * @return (possible error code,
                hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
    function getHypotheticalAccountLiquidityInternal(
        address account,
        CToken cTokenModify,
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

        // add all Uni V3 LP Collateral value
        addNFTCollateral(account, vars);

        // For each asset the account is in
        CToken[] memory assets = accountAssets[account];
        for (uint256 i = 0; i < assets.length; i++) {
            CToken asset = assets[i];

            // Read the balances and exchange rate from the cToken
            (oErr, vars.cTokenBalance, vars.borrowBalance, vars.exchangeRateMantissa) = asset.getAccountSnapshot(
                account
            );
            if (oErr != 0) {
                // semi-opaque error code, we assume NO_ERROR == 0 is invariant between upgrades
                return (Error.SNAPSHOT_ERROR, 0, 0);
            }
            vars.collateralFactor = Exp({ mantissa: markets[address(asset)].collateralFactorMantissa });
            vars.exchangeRate = Exp({ mantissa: vars.exchangeRateMantissa });

            // Get the normalized price of the asset
            vars.oraclePriceMantissa = oracle.getUnderlyingPrice(asset);
            if (vars.oraclePriceMantissa == 0) {
                return (Error.PRICE_ERROR, 0, 0);
            }
            vars.oraclePrice = Exp({ mantissa: vars.oraclePriceMantissa });

            // Pre-compute a conversion factor from tokens -> ether (normalized price value)
            vars.tokensToDenom = mul_(mul_(vars.collateralFactor, vars.exchangeRate), vars.oraclePrice);

            // sumCollateral += tokensToDenom * cTokenBalance
            vars.sumCollateral = mul_ScalarTruncateAddUInt(vars.tokensToDenom, vars.cTokenBalance, vars.sumCollateral);

            // sumBorrowPlusEffects += oraclePrice * borrowBalance
            vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(
                vars.oraclePrice,
                vars.borrowBalance,
                vars.sumBorrowPlusEffects
            );

            // Calculate effects of interacting with cTokenModify
            if (asset == cTokenModify) {
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
        if (vars.sumCollateral > vars.sumBorrowPlusEffects) {
            return (Error.NO_ERROR, vars.sumCollateral - vars.sumBorrowPlusEffects, 0);
        } else {
            return (Error.NO_ERROR, 0, vars.sumBorrowPlusEffects - vars.sumCollateral);
        }
    }

    /**
     * @notice Calculate number of tokens of collateral asset to seize given an underlying amount
     * @dev Used in liquidation (called in cToken.liquidateBorrowFresh)
     * @param cTokenBorrowed The address of the borrowed cToken
     * @param cTokenCollateral The address of the collateral cToken
     * @param actualRepayAmount The amount of cTokenBorrowed underlying to convert into cTokenCollateral tokens
     * @return (errorCode, number of cTokenCollateral tokens to be seized in a liquidation)
     */
    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint256 actualRepayAmount
    ) external view returns (uint256, uint256) {
        /* Read oracle prices for borrowed and collateral markets */
        uint256 priceBorrowedMantissa = oracle.getUnderlyingPrice(CToken(cTokenBorrowed));
        uint256 priceCollateralMantissa = oracle.getUnderlyingPrice(CToken(cTokenCollateral));
        if (priceBorrowedMantissa == 0 || priceCollateralMantissa == 0) {
            return (uint256(Error.PRICE_ERROR), 0);
        }

        /*
         * Get the exchange rate and calculate the number of collateral tokens to seize:
         *  seizeAmount = actualRepayAmount * liquidationIncentive * priceBorrowed / priceCollateral
         *  seizeTokens = seizeAmount / exchangeRate
         *   = actualRepayAmount * (liquidationIncentive * priceBorrowed) / (priceCollateral * exchangeRate)
         */
        uint256 exchangeRateMantissa = CToken(cTokenCollateral).exchangeRateStored(); // Note: reverts on error
        uint256 seizeTokens;
        Exp memory numerator;
        Exp memory denominator;
        Exp memory ratio;

        numerator = mul_(Exp({ mantissa: liquidationIncentiveMantissa }), Exp({ mantissa: priceBorrowedMantissa }));
        denominator = mul_(Exp({ mantissa: priceCollateralMantissa }), Exp({ mantissa: exchangeRateMantissa }));
        ratio = div_(numerator, denominator);

        seizeTokens = mul_ScalarTruncate(ratio, actualRepayAmount);

        return (uint256(Error.NO_ERROR), seizeTokens);
    }

    // to avoid stack-too-deep errors on `liquidateCalculateSeizeTokensUniV3`
    struct LiquidationSeizeLocalVars {
        uint256 amountToken0Fees;
        uint256 amountToken1Fees;
        uint256 amountToken0Liquidity;
        uint256 amountToken1Liquidity;
        uint256 amountLiquidity;
        Exp borrowValue;
        Exp feeValue;
        Exp liquidityValue;
    }

    /**
     * @notice Calculate amount of liquidity NFT to seize given an underlying amount
     * @dev Used in liquidation (called in cToken.liquidateBorrowUniV3Fresh)
     * @param cTokenBorrowed The address of the borrowed cToken
     * @param collateralTokenId The NFT tokenId to (partially) seize from the borrower
     * @param actualRepayAmount The amount of cTokenBorrowed underlying to convert into cTokenCollateral tokens
     * @return (errorCode, percent of fees to be seized, amount of colalteralTokenId liquidity to be seized in a liquidation)
     */
    function liquidateCalculateSeizeTokensUniV3(
        address cTokenBorrowed,
        uint256 collateralTokenId,
        uint256 actualRepayAmount
    )
        external
        view
        returns (
            uint256,
            uint128,
            uint128,
            uint128
        )
    {
        LiquidationSeizeLocalVars memory vars;

        /*
         * take the value in eth, convert it to borrow value. see what % the repay borrow + incentive.
         * if % < 100, then return 0 on liquidity.
         * If above 100%, take % - 100 to get value that should be removed from total liquidity.
         * Then take that value, divided by the total value of the liquidity, and multiply by the amount of liquidity.
         * Cap this liquidity amount at the total liquidity amount (since we've already liquidated everything)
         */

        uint256 oraclePriceMantissa0;
        uint256 oraclePriceMantissa1;
        {
            (address token0, address token1) = tickOracle.getTokens(collateralTokenId);
            oraclePriceMantissa0 = oracle.getUnderlyingPrice(cTokensByUnderlying[token0]);
            oraclePriceMantissa1 = oracle.getUnderlyingPrice(cTokensByUnderlying[token1]);
            (
                vars.amountToken0Fees,
                vars.amountToken1Fees,
                vars.amountToken0Liquidity,
                vars.amountToken1Liquidity,
                vars.amountLiquidity
            ) = tickOracle.getTokenBreakdownChainlink(collateralTokenId, oraclePriceMantissa0, oraclePriceMantissa1);
        }

        uint256 priceBorrowedMantissa = oracle.getUnderlyingPrice(CToken(cTokenBorrowed));
        if (priceBorrowedMantissa == 0 || oraclePriceMantissa0 == 0 || oraclePriceMantissa1 == 0) {
            return (uint256(Error.PRICE_ERROR), 0, 0, 0);
        }

        vars.borrowValue = mul_(
            mul_(Exp({ mantissa: liquidationIncentiveUniV3Mantissa }), Exp({ mantissa: priceBorrowedMantissa })),
            actualRepayAmount
        );
        vars.feeValue = add_(
            mul_(Exp({ mantissa: oraclePriceMantissa0 }), vars.amountToken0Fees),
            mul_(Exp({ mantissa: oraclePriceMantissa1 }), vars.amountToken1Fees)
        );
        vars.liquidityValue = add_(
            mul_(Exp({ mantissa: oraclePriceMantissa0 }), vars.amountToken0Liquidity),
            mul_(Exp({ mantissa: oraclePriceMantissa1 }), vars.amountToken1Liquidity)
        );

        require(
            lessThanOrEqualExp(vars.borrowValue, add_(vars.feeValue, vars.liquidityValue)),
            "borrowValue greater than total collateral"
        );

        if (lessThanOrEqualExp(vars.borrowValue, vars.feeValue)) {
            // only return from fees
            uint128 seizeAmountToken0Fees = uint128(
                mul_ScalarTruncate(div_(vars.borrowValue, vars.feeValue), vars.amountToken0Fees)
            );
            uint128 seizeAmountToken1Fees = uint128(
                mul_ScalarTruncate(div_(vars.borrowValue, vars.feeValue), vars.amountToken1Fees)
            );
            return (uint256(Error.NO_ERROR), seizeAmountToken0Fees, seizeAmountToken1Fees, 0);
        } else {
            // only return from liquidity
            uint128 seizeAmountLiquidity = uint128(
                mul_ScalarTruncate(
                    div_(sub_(vars.borrowValue, vars.feeValue), vars.liquidityValue),
                    vars.amountLiquidity
                )
            );
            return (
                uint256(Error.NO_ERROR),
                uint128(vars.amountToken0Fees),
                uint128(vars.amountToken1Fees),
                seizeAmountLiquidity
            );
        }
    }

    /*** Admin Functions ***/

    /**
     * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @param newPendingAdmin New pending admin.
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setPendingAdmin(address newPendingAdmin) public returns (uint256) {
        // Check caller = admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PENDING_ADMIN_OWNER_CHECK);
        }

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
     * @dev Admin function for pending admin to accept role and update admin
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _acceptAdmin() public returns (uint256) {
        // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
        if (msg.sender != pendingAdmin || msg.sender == address(0)) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ACCEPT_ADMIN_PENDING_ADMIN_CHECK);
        }

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Sets a new price oracle for the comptroller
     * @dev Admin function to set a new price oracle
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setPriceOracle(PriceOracle newOracle) public returns (uint256) {
        // Check caller is admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PRICE_ORACLE_OWNER_CHECK);
        }

        // Track the old oracle for the comptroller
        PriceOracle oldOracle = oracle;

        // Set comptroller's oracle to newOracle
        oracle = newOracle;

        // Emit NewPriceOracle(oldOracle, newOracle)
        emit NewPriceOracle(oldOracle, newOracle);

        return uint256(Error.NO_ERROR);
    }

    function _setTickOracle(IChainlinkTickOracle newTickOracle) public returns (uint256) {
        // Check caller is admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_TICK_ORACLE_OWNER_CHECK);
        }

        // Track the old oracle for the comptroller
        IChainlinkTickOracle oldTickOracle = tickOracle;

        // Set comptroller's oracle to newOracle
        tickOracle = newTickOracle;

        // Emit NewTickOracle(oldTickOracle, newTickOracle)
        emit NewTickOracle(oldTickOracle, newTickOracle);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Sets a new UniV3LpVault for the comptroller
     * @dev Admin function to set a new UniV3LpVault
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setUniV3LpVault(IUniV3LpVault newVault) public returns (uint256) {
        // Check caller is admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PRICE_ORACLE_OWNER_CHECK);
        }
        require(address(uniV3LpVault) == address(0), "uniV3LpVault already set");

        // Track the old vault for the comptroller
        IUniV3LpVault oldVault = uniV3LpVault;

        // Set comptroller's uniV3LpVault to newVault
        uniV3LpVault = newVault;

        // Emit NewUniV3LpVault(oldVault, newVault)
        emit NewUniV3LpVault(oldVault, newVault);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Sets the closeFactor used when liquidating borrows
     * @dev Admin function to set closeFactor
     * @param newCloseFactorMantissa New close factor, scaled by 1e18
     * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
     */
    function _setCloseFactor(uint256 newCloseFactorMantissa) external returns (uint256) {
        // Check caller is admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_CLOSE_FACTOR_OWNER_CHECK);
        }

        // Check limits
        Exp memory newCloseFactorExp = Exp({ mantissa: newCloseFactorMantissa });
        Exp memory lowLimit = Exp({ mantissa: closeFactorMinMantissa });
        if (lessThanOrEqualExp(newCloseFactorExp, lowLimit)) {
            return fail(Error.INVALID_CLOSE_FACTOR, FailureInfo.SET_CLOSE_FACTOR_VALIDATION);
        }

        Exp memory highLimit = Exp({ mantissa: closeFactorMaxMantissa });
        if (lessThanExp(highLimit, newCloseFactorExp)) {
            return fail(Error.INVALID_CLOSE_FACTOR, FailureInfo.SET_CLOSE_FACTOR_VALIDATION);
        }

        // Set pool close factor to new close factor, remember old value
        uint256 oldCloseFactorMantissa = closeFactorMantissa;
        closeFactorMantissa = newCloseFactorMantissa;

        // Emit event
        emit NewCloseFactor(oldCloseFactorMantissa, closeFactorMantissa);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Sets the collateralFactor for a market
     * @dev Admin function to set per-market collateralFactor
     * @param cToken The market to set the factor on
     * @param newCollateralFactorMantissa The new collateral factor, scaled by 1e18
     * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
     */
    function _setCollateralFactor(CToken cToken, uint256 newCollateralFactorMantissa) external returns (uint256) {
        // Check caller is admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_COLLATERAL_FACTOR_OWNER_CHECK);
        }

        // Verify market is listed
        Market storage market = markets[address(cToken)];
        if (!market.isListed) {
            return fail(Error.MARKET_NOT_LISTED, FailureInfo.SET_COLLATERAL_FACTOR_NO_EXISTS);
        }

        Exp memory newCollateralFactorExp = Exp({ mantissa: newCollateralFactorMantissa });

        // Check collateral factor <= 0.9
        Exp memory highLimit = Exp({ mantissa: collateralFactorMaxMantissa });
        if (lessThanExp(highLimit, newCollateralFactorExp)) {
            return fail(Error.INVALID_COLLATERAL_FACTOR, FailureInfo.SET_COLLATERAL_FACTOR_VALIDATION);
        }

        // If collateral factor != 0, fail if price == 0
        if (newCollateralFactorMantissa != 0 && oracle.getUnderlyingPrice(cToken) == 0) {
            return fail(Error.PRICE_ERROR, FailureInfo.SET_COLLATERAL_FACTOR_WITHOUT_PRICE);
        }

        // Set market's collateral factor to new collateral factor, remember old value
        uint256 oldCollateralFactorMantissa = market.collateralFactorMantissa;
        market.collateralFactorMantissa = newCollateralFactorMantissa;

        // Emit event with asset, old collateral factor, and new collateral factor
        emit NewCollateralFactor(cToken, oldCollateralFactorMantissa, newCollateralFactorMantissa);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Sets liquidationIncentive
     * @dev Admin function to set liquidationIncentive
     * @param newLiquidationIncentiveMantissa New liquidationIncentive scaled by 1e18
     * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
     */
    function _setLiquidationIncentive(uint256 newLiquidationIncentiveMantissa) external returns (uint256) {
        // Check caller is admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_LIQUIDATION_INCENTIVE_OWNER_CHECK);
        }

        uint256 error = _checkNewLiquidationIncentiveValue(newLiquidationIncentiveMantissa);
        if (error != uint256(Error.NO_ERROR)) {
            return error;
        }

        // Save current value for use in log
        uint256 oldLiquidationIncentiveMantissa = liquidationIncentiveMantissa;

        // Set liquidation incentive to new incentive
        liquidationIncentiveMantissa = newLiquidationIncentiveMantissa;

        // Emit event with old incentive, new incentive
        emit NewLiquidationIncentive(oldLiquidationIncentiveMantissa, newLiquidationIncentiveMantissa);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Sets liquidationIncentiveUniV3
     * @dev Admin function to set liquidationIncentiveUniV3
     * @param newLiquidationIncentiveMantissa New liquidationIncentiveUniV3 scaled by 1e18
     * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
     */
    function _setLiquidationIncentiveUniV3(uint256 newLiquidationIncentiveMantissa) external returns (uint256) {
        // Check caller is admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_LIQUIDATION_INCENTIVE_OWNER_CHECK);
        }

        uint256 error = _checkNewLiquidationIncentiveValue(newLiquidationIncentiveMantissa);
        if (error != uint256(Error.NO_ERROR)) {
            return error;
        }

        // Save current value for use in log
        uint256 oldLiquidationIncentiveMantissa = liquidationIncentiveUniV3Mantissa;

        // Set liquidation incentive to new incentive
        liquidationIncentiveUniV3Mantissa = newLiquidationIncentiveMantissa;

        // Emit event with old incentive, new incentive
        emit NewLiquidationIncentiveUniV3(oldLiquidationIncentiveMantissa, newLiquidationIncentiveMantissa);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Checks that new liquidation incentive is within allowed range
     * @dev Check de-scaled min <= newLiquidationIncentive <= max
     * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
     */
    function _checkNewLiquidationIncentiveValue(uint256 newLiquidationIncentiveMantissa) internal returns (uint256) {
        Exp memory newLiquidationIncentive = Exp({ mantissa: newLiquidationIncentiveMantissa });
        Exp memory minLiquidationIncentive = Exp({ mantissa: liquidationIncentiveMinMantissa });
        if (lessThanExp(newLiquidationIncentive, minLiquidationIncentive)) {
            return fail(Error.INVALID_LIQUIDATION_INCENTIVE, FailureInfo.SET_LIQUIDATION_INCENTIVE_VALIDATION);
        }

        Exp memory maxLiquidationIncentive = Exp({ mantissa: liquidationIncentiveMaxMantissa });
        if (lessThanExp(maxLiquidationIncentive, newLiquidationIncentive)) {
            return fail(Error.INVALID_LIQUIDATION_INCENTIVE, FailureInfo.SET_LIQUIDATION_INCENTIVE_VALIDATION);
        }

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Add the market to the markets mapping and set it as listed
     * @dev Admin function to set isListed and add support for the market
     * @param cToken The address of the market (token) to list
     * @return uint 0=success, otherwise a failure. (See enum Error for details)
     */
    function _supportMarket(CToken cToken) external returns (uint256) {
        // Check caller is admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SUPPORT_MARKET_OWNER_CHECK);
        }

        // Is market already listed?
        if (markets[address(cToken)].isListed) {
            return fail(Error.MARKET_ALREADY_LISTED, FailureInfo.SUPPORT_MARKET_EXISTS);
        }

        // Sanity check to make sure its really a CToken
        require(cToken.isCToken(), "marker method returned false");

        // Check cToken.comptroller == this
        require(
            address(cToken.comptroller()) == address(this),
            "Cannot support a market with a different Comptroller."
        );

        // Make sure market is not already listed
        address underlying = CErc20(address(cToken)).underlying();

        if (address(cTokensByUnderlying[underlying]) != address(0)) {
            return fail(Error.MARKET_ALREADY_LISTED, FailureInfo.SUPPORT_MARKET_EXISTS);
        }

        // List market and emit event
        markets[address(cToken)] = Market({ isListed: true, collateralFactorMantissa: 0 });
        allMarkets.push(cToken);
        cTokensByUnderlying[underlying] = cToken;
        emit MarketListed(cToken);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Removed a market from the markets mapping and sets it as unlisted
     * @dev Admin function unset isListed and collateralFactorMantissa and unadd support for the market
     * @param cToken The address of the market (token) to unlist
     * @return uint 0=success, otherwise a failure. (See enum Error for details)
     */
    function _unsupportMarket(CToken cToken) external returns (uint256) {
        // Check admin rights
        if (msg.sender != admin) return fail(Error.UNAUTHORIZED, FailureInfo.UNSUPPORT_MARKET_OWNER_CHECK);

        // Check if market is already unlisted
        if (!markets[address(cToken)].isListed)
            return fail(Error.MARKET_NOT_LISTED, FailureInfo.UNSUPPORT_MARKET_DOES_NOT_EXIST);

        // Check if market is in use
        if (cToken.totalSupply() > 0) return fail(Error.NONZERO_TOTAL_SUPPLY, FailureInfo.UNSUPPORT_MARKET_IN_USE);

        // Unlist market
        delete markets[address(cToken)];

        /* Delete cToken from allMarkets */
        // load into memory for faster iteration
        CToken[] memory _allMarkets = allMarkets;
        uint256 len = _allMarkets.length;
        uint256 assetIndex = len;
        for (uint256 i = 0; i < len; i++) {
            if (_allMarkets[i] == cToken) {
                assetIndex = i;
                break;
            }
        }

        // We *must* have found the asset in the list or our redundant data structure is broken
        assert(assetIndex < len);

        // copy last item in list to location of item to be removed, reduce length by 1
        allMarkets[assetIndex] = allMarkets[allMarkets.length - 1];
        allMarkets.length--;

        cTokensByUnderlying[CErc20(address(cToken)).underlying()] = CToken(address(0));
        emit MarketUnlisted(cToken);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Set the given supply caps for the given cToken markets. Supplying that brings total underlying supply to or above supply cap will revert.
     * @dev Admin or borrowCapGuardian function to set the supply caps. A supply cap of 0 corresponds to unlimited supplying.
     * @param cTokens The addresses of the markets (tokens) to change the supply caps for
     * @param newSupplyCaps The new supply cap values in underlying to be set. A value of 0 corresponds to unlimited supplying.
     */
    function _setMarketSupplyCaps(CToken[] calldata cTokens, uint256[] calldata newSupplyCaps) external {
        require(
            msg.sender == admin || msg.sender == borrowCapGuardian,
            "only admin or borrow cap guardian can set supply caps"
        );

        uint256 numMarkets = cTokens.length;
        uint256 numSupplyCaps = newSupplyCaps.length;

        require(numMarkets != 0 && numMarkets == numSupplyCaps, "invalid input");

        for (uint256 i = 0; i < numMarkets; i++) {
            supplyCaps[address(cTokens[i])] = newSupplyCaps[i];
            emit NewSupplyCap(cTokens[i], newSupplyCaps[i]);
        }
    }

    /**
     * @notice Set the given borrow caps for the given cToken markets. Borrowing that brings total borrows to or above borrow cap will revert.
     * @dev Admin or borrowCapGuardian function to set the borrow caps. A borrow cap of 0 corresponds to unlimited borrowing.
     * @param cTokens The addresses of the markets (tokens) to change the borrow caps for
     * @param newBorrowCaps The new borrow cap values in underlying to be set. A value of 0 corresponds to unlimited borrowing.
     */
    function _setMarketBorrowCaps(CToken[] calldata cTokens, uint256[] calldata newBorrowCaps) external {
        require(
            msg.sender == admin || msg.sender == borrowCapGuardian,
            "only admin or borrow cap guardian can set borrow caps"
        );

        uint256 numMarkets = cTokens.length;
        uint256 numBorrowCaps = newBorrowCaps.length;

        require(numMarkets != 0 && numMarkets == numBorrowCaps, "invalid input");

        for (uint256 i = 0; i < numMarkets; i++) {
            borrowCaps[address(cTokens[i])] = newBorrowCaps[i];
            emit NewBorrowCap(cTokens[i], newBorrowCaps[i]);
        }
    }

    /**
     * @notice Admin function to change the Borrow Cap Guardian
     * @param newBorrowCapGuardian The address of the new Borrow Cap Guardian
     */
    function _setBorrowCapGuardian(address newBorrowCapGuardian) external {
        require(msg.sender == admin, "only admin can set borrow cap guardian");

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
    function _setPauseGuardian(address newPauseGuardian) public returns (uint256) {
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PAUSE_GUARDIAN_OWNER_CHECK);
        }

        // Save current value for inclusion in log
        address oldPauseGuardian = pauseGuardian;

        // Store pauseGuardian with value newPauseGuardian
        pauseGuardian = newPauseGuardian;

        // Emit NewPauseGuardian(OldPauseGuardian, NewPauseGuardian)
        emit NewPauseGuardian(oldPauseGuardian, pauseGuardian);

        return uint256(Error.NO_ERROR);
    }

    function _setMintPaused(CToken cToken, bool state) public returns (bool) {
        require(markets[address(cToken)].isListed, "cannot pause a market that is not listed");
        require(msg.sender == pauseGuardian || msg.sender == admin, "only pause guardian and admin can pause");
        require(msg.sender == admin || state == true, "only admin can unpause");

        mintGuardianPaused[address(cToken)] = state;
        emit ActionPausedMarket(cToken, "Mint", state);
        return state;
    }

    function _setBorrowPaused(CToken cToken, bool state) public returns (bool) {
        require(markets[address(cToken)].isListed, "cannot pause a market that is not listed");
        require(msg.sender == pauseGuardian || msg.sender == admin, "only pause guardian and admin can pause");
        require(msg.sender == admin || state == true, "only admin can unpause");

        borrowGuardianPaused[address(cToken)] = state;
        emit ActionPausedMarket(cToken, "Borrow", state);
        return state;
    }

    function _setTransferPaused(bool state) public returns (bool) {
        require(msg.sender == pauseGuardian || msg.sender == admin, "only pause guardian and admin can pause");
        require(msg.sender == admin || state == true, "only admin can unpause");

        transferGuardianPaused = state;
        emit ActionPaused("Transfer", state);
        return state;
    }

    function _setSeizePaused(bool state) public returns (bool) {
        require(msg.sender == pauseGuardian || msg.sender == admin, "only pause guardian and admin can pause");
        require(msg.sender == admin || state == true, "only admin can unpause");

        seizeGuardianPaused = state;
        emit ActionPaused("Seize", state);
        return state;
    }

    /**
     * @notice sets the state for many pools of whether or not they are supported as collateral
     *              in actuality, just limits whether or not a pool can be deposited into the vault
     * @param pools The addresses of Uni V3 Pools
     * @param states The state of whether or not this pool is to be supported (corresponding by index to pools)
     */
    function _setSupportedPools(address[] calldata pools, bool[] calldata states) external {
        require(msg.sender == admin, "only admin can set supported pools");
        require(pools.length > 0, "must have at least one pool");
        require(pools.length == states.length, "Number of pools and states must be equal");
        for (uint256 i = 0; i < pools.length; i++) {
            isSupportedPool[pools[i]] = states[i];
        }
    }

    /**
     * @notice sets the collateral factors for many pools at once
     * @param pools The addresses of Uni V3 Pools
     * @param collateralFactorsMantissa The collateral factors for LP positions of the pools
     */
    function _setPoolCollateralFactors(address[] calldata pools, uint256[] calldata collateralFactorsMantissa)
        external
        returns (uint256)
    {
        require(pools.length > 0, "must have at least one pool");
        require(
            pools.length == collateralFactorsMantissa.length,
            "Number of pools and collateralFactors must be equal"
        );
        for (uint256 i = 0; i < pools.length; i++) {
            uint256 err = _setPoolCollateralFactorInternal(pools[i], collateralFactorsMantissa[i]);
            if (err != uint256(Error.NO_ERROR)) {
                return uint256(err);
            }
        }

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice sets the collateral factor for a pool
     * @param pool The addresses of Uni V3 Pool
     * @param newCollateralFactorMantissa The collateral factor for LP positions of the pool
     */
    function _setPoolCollateralFactor(address pool, uint256 newCollateralFactorMantissa) external returns (uint256) {
        return _setPoolCollateralFactorInternal(pool, newCollateralFactorMantissa);
    }

    /**
     * @notice sets the collateral factor for a pool
     * @param pool The addresses of Uni V3 Pool
     * @param newCollateralFactorMantissa The collateral factor for LP positions of the pool
     */
    function _setPoolCollateralFactorInternal(address pool, uint256 newCollateralFactorMantissa)
        internal
        returns (uint256)
    {
        // Check caller is admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_COLLATERAL_FACTOR_OWNER_CHECK);
        }

        Exp memory newCollateralFactorExp = Exp({ mantissa: newCollateralFactorMantissa });

        // Check collateral factor <= 0.9
        Exp memory highLimit = Exp({ mantissa: collateralFactorMaxMantissa });
        if (lessThanExp(highLimit, newCollateralFactorExp)) {
            return fail(Error.INVALID_COLLATERAL_FACTOR, FailureInfo.SET_COLLATERAL_FACTOR_VALIDATION);
        }

        // Set market's collateral factor to new collateral factor, remember old value
        uint256 oldCollateralFactorMantissa = poolCollateralFactors[pool];
        poolCollateralFactors[pool] = newCollateralFactorMantissa;

        // Emit event with asset, old collateral factor, and new collateral factor
        emit NewPoolCollateralFactor(pool, oldCollateralFactorMantissa, newCollateralFactorMantissa);

        return uint256(Error.NO_ERROR);
    }

    /*** Helper Functions ***/

    /**
     * @notice Return all of the markets
     * @dev The automatic getter may be used to access an individual market.
     * @return The list of market addresses
     */
    function getAllMarkets() public view returns (CToken[] memory) {
        return allMarkets;
    }

    /**
     * @notice Return all of the borrowers
     * @dev The automatic getter may be used to access an individual borrower.
     * @return The list of borrower account addresses
     */
    function getAllBorrowers() public view returns (address[] memory) {
        return allBorrowers;
    }

    /**
     * @notice Returns true if the given cToken market has been deprecated
     * @dev All borrows in a deprecated cToken market can be immediately liquidated
     * @param cToken The market to check if deprecated
     */
    function isDeprecated(CToken cToken) public view returns (bool) {
        return
            markets[address(cToken)].collateralFactorMantissa == 0 &&
            borrowGuardianPaused[address(cToken)] == true &&
            cToken.reserveFactorMantissa() == 1e18;
    }

    /*** Pool-Wide/Cross-Asset Reentrancy Prevention ***/

    /**
     * @dev Called by cTokens before a non-reentrant function for pool-wide reentrancy prevention.
     * Prevents pool-wide/cross-asset reentrancy exploits like AMP on Cream.
     */
    function _beforeNonReentrant() external {
        require(
            markets[msg.sender].isListed || msg.sender == address(uniV3LpVault),
            "Comptroller:_beforeNonReentrant: caller not listed as market or lpVault"
        );
        require(_notEntered, "re-entered across assets");
        _notEntered = false;
    }

    /**
     * @dev Called by cTokens after a non-reentrant function for pool-wide reentrancy prevention.
     * Prevents pool-wide/cross-asset reentrancy exploits like AMP on Cream.
     */
    function _afterNonReentrant() external {
        require(
            markets[msg.sender].isListed || msg.sender == address(uniV3LpVault),
            "Comptroller:_afterNonReentrant: caller not listed as market or lpVault"
        );
        _notEntered = true; // get a gas-refund post-Istanbul
    }
}