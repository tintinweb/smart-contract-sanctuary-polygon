// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./IAmmDataProvider.sol";
import "./IMinterAmm.sol";
import "../token/IERC20Lib.sol";
import "../series/ISeriesController.sol";
import "../series/IPriceOracle.sol";
import "../series/SeriesLibrary.sol";
import "../libraries/Math.sol";
import "./IBlackScholes.sol";
import "../configuration/IAddressesProvider.sol";
import "./IWTokenVault.sol";

contract AmmDataProvider is IAmmDataProvider {
    ISeriesController public seriesController;
    IERC1155 public erc1155Controller;
    IAddressesProvider public addressesProvider;

    event AmmDataProviderCreated(
        ISeriesController seriesController,
        IERC1155 erc1155Controller,
        IAddressesProvider addressesProvider
    );

    constructor(
        ISeriesController _seriesController,
        IERC1155 _erc1155Controller,
        IAddressesProvider _addressProvider
    ) {
        require(
            address(_addressProvider) != address(0x0),
            "AmmDataProvider: _addressProvider cannot be the 0x0 address"
        );

        require(
            address(_seriesController) != address(0x0),
            "AmmDataProvider: _seriesController cannot be the 0x0 address"
        );
        require(
            address(_erc1155Controller) != address(0x0),
            "AmmDataProvider: _erc1155Controller cannot be the 0x0 address"
        );

        seriesController = _seriesController;
        erc1155Controller = _erc1155Controller;
        addressesProvider = _addressProvider;

        emit AmmDataProviderCreated(
            _seriesController,
            _erc1155Controller,
            _addressProvider
        );
    }

    /// This function determines reserves of a bonding curve for a specific series.
    /// Given price of bToken we determine what is the largest pool we can create such that
    /// the ratio of its reserves satisfy the given bToken price: Rb / Rw = (1 - Pb) / Pb
    function getVirtualReserves(
        uint64 seriesId,
        address ammAddress,
        uint256 collateralTokenBalance,
        uint256 bTokenPrice
    ) public view override returns (uint256, uint256) {
        // Get residual balances
        uint256 bTokenBalance = 0; // no bTokens are allowed in the pool
        uint256 wTokenBalance = erc1155Controller.balanceOf(
            ammAddress,
            SeriesLibrary.wTokenIndex(seriesId)
        );

        ISeriesController.Series memory series = seriesController.series(
            seriesId
        );

        // For put convert token balances into collateral locked in them
        uint256 lockedUnderlyingValue = 1e18;
        if (series.isPutOption) {
            wTokenBalance = seriesController.getCollateralPerOptionToken(
                seriesId,
                wTokenBalance
            );
            // TODO: this logic causes the underlying price to be fetched twice from the oracle. Can be optimized.
            lockedUnderlyingValue =
                (lockedUnderlyingValue * series.strikePrice) /
                IPriceOracle(addressesProvider.getPriceOracle())
                    .getCurrentPrice(
                        seriesController.underlyingToken(seriesId),
                        seriesController.priceToken(seriesId)
                    );
        }

        // Max amount of tokens we can get by adding current balance plus what can be minted from collateral
        uint256 bTokenBalanceMax = bTokenBalance + collateralTokenBalance;
        uint256 wTokenBalanceMax = wTokenBalance + collateralTokenBalance;

        uint256 wTokenPrice = lockedUnderlyingValue - bTokenPrice;

        // Balance on higher reserve side is the sum of what can be minted (collateralTokenBalance)
        // plus existing balance of the token
        uint256 bTokenVirtualBalance;
        uint256 wTokenVirtualBalance;

        if (bTokenPrice <= wTokenPrice) {
            // Rb >= Rw, Pb <= Pw
            bTokenVirtualBalance = bTokenBalanceMax;
            wTokenVirtualBalance =
                (bTokenVirtualBalance * bTokenPrice) /
                wTokenPrice;

            // Sanity check that we don't exceed actual physical balances
            // In case this happens, adjust virtual balances to not exceed maximum
            // available reserves while still preserving correct price
            if (wTokenVirtualBalance > wTokenBalanceMax) {
                wTokenVirtualBalance = wTokenBalanceMax;
                bTokenVirtualBalance =
                    (wTokenVirtualBalance * wTokenPrice) /
                    bTokenPrice;
            }
        } else {
            // if Rb < Rw, Pb > Pw
            wTokenVirtualBalance = wTokenBalanceMax;
            bTokenVirtualBalance =
                (wTokenVirtualBalance * wTokenPrice) /
                bTokenPrice;

            // Sanity check
            if (bTokenVirtualBalance > bTokenBalanceMax) {
                bTokenVirtualBalance = bTokenBalanceMax;
                wTokenVirtualBalance =
                    (bTokenVirtualBalance * bTokenPrice) /
                    wTokenPrice;
            }
        }

        return (bTokenVirtualBalance, wTokenVirtualBalance);
    }

    /// @notice Calculate premium (i.e. the option price) to buy bTokenAmount bTokens for the
    /// given Series
    /// @notice The premium depends on the amount of collateral token in the pool, the reserves
    /// of bToken and wToken in the pool, and the current series price of the underlying
    /// @param seriesId The ID of the Series to buy bToken on
    /// @param ammAddress The AMM whose reserves we'll use
    /// @param bTokenAmount The amount of bToken to buy, which uses the same decimals as
    /// the underlying ERC20 token
    /// @return The amount of collateral token necessary to buy bTokenAmount worth of bTokens
    function bTokenGetCollateralIn(
        uint64 seriesId,
        address ammAddress,
        uint256 bTokenAmount,
        uint256 collateralTokenBalance,
        uint256 bTokenPrice
    ) public view override returns (uint256) {
        // Shortcut for 0 amount
        if (bTokenAmount == 0) return 0;

        bTokenAmount = seriesController.getCollateralPerOptionToken(
            seriesId,
            bTokenAmount
        );

        // For both puts and calls balances are expressed in collateral token
        (uint256 bTokenBalance, uint256 wTokenBalance) = getVirtualReserves(
            seriesId,
            ammAddress,
            collateralTokenBalance,
            bTokenPrice
        );

        uint256 sumBalance = bTokenBalance + wTokenBalance;
        uint256 toSquare;
        if (sumBalance > bTokenAmount) {
            toSquare = sumBalance - bTokenAmount;
        } else {
            toSquare = bTokenAmount - sumBalance;
        }

        // return the collateral amount
        return
            (((Math.sqrt((toSquare**2) + (4 * bTokenAmount * wTokenBalance)) +
                bTokenAmount) - bTokenBalance) - wTokenBalance) / 2;
    }

    /// @dev Calculates the amount of collateral token a seller will receive for selling their option tokens,
    /// taking into account the AMM's level of reserves
    /// @param seriesId The ID of the Series
    /// @param ammAddress The AMM whose reserves we'll use
    /// @param optionTokenAmount The amount of option tokens (either bToken or wToken) to be sold
    /// @param collateralTokenBalance The amount of collateral token held by this AMM
    /// @param bTokenPrice The price of 1 (human readable unit) bToken for this series, in units of collateral token
    /// @param isBToken true if the option token is bToken, and false if it's wToken. Depending on which
    /// of the two it is, the equation for calculating the final collateral token is a little different
    /// @return The amount of collateral token the seller will receive in exchange for their option token
    function optionTokenGetCollateralOut(
        uint64 seriesId,
        address ammAddress,
        uint256 optionTokenAmount,
        uint256 collateralTokenBalance,
        uint256 bTokenPrice,
        bool isBToken
    ) public view override returns (uint256) {
        // Shortcut for 0 amount
        if (optionTokenAmount == 0) return 0;

        optionTokenAmount = seriesController.getCollateralPerOptionToken(
            seriesId,
            optionTokenAmount
        );

        (uint256 bTokenBalance, uint256 wTokenBalance) = getVirtualReserves(
            seriesId,
            ammAddress,
            collateralTokenBalance,
            bTokenPrice
        );

        uint256 balanceFactor;
        if (isBToken) {
            balanceFactor = wTokenBalance;
        } else {
            balanceFactor = bTokenBalance;
        }
        uint256 toSquare = optionTokenAmount + wTokenBalance + bTokenBalance;
        uint256 collateralAmount = (toSquare -
            Math.sqrt(
                (toSquare**2) - (4 * optionTokenAmount * balanceFactor)
            )) / 2;

        return collateralAmount;
    }

    /// @dev Calculate the collateral amount receivable by redeeming the given
    /// Series' bTokens and wToken
    /// @param seriesId The index of the Series
    /// @param wTokenBalance The wToken balance for this Series owned by this AMM
    /// @return The total amount of collateral receivable by redeeming the Series' option tokens
    function getRedeemableCollateral(uint64 seriesId, uint256 wTokenBalance)
        public
        view
        override
        returns (uint256)
    {
        uint256 unredeemedCollateral = 0;
        if (wTokenBalance > 0) {
            (uint256 unclaimedCollateral, ) = seriesController.getClaimAmount(
                seriesId,
                wTokenBalance
            );
            unredeemedCollateral += unclaimedCollateral;
        }

        return unredeemedCollateral;
    }

    /// @notice Calculate the amount of collateral the AMM would received if all of the
    /// expired Series' wTokens and bTokens were to be redeemed for their underlying collateral
    /// value
    /// @return The amount of collateral token the AMM would receive if it were to exercise/claim
    /// all expired bTokens/wTokens
    function getCollateralValueOfAllExpiredOptionTokens(
        uint64[] memory openSeries,
        address ammAddress
    ) public view override returns (uint256) {
        IWTokenVault wTokenVault = IWTokenVault(
            addressesProvider.getWTokenVault()
        );

        uint256 unredeemedCollateral = 0;

        for (uint256 i = 0; i < openSeries.length; i++) {
            uint64 seriesId = openSeries[i];

            if (
                seriesController.state(seriesId) ==
                ISeriesController.SeriesState.EXPIRED
            ) {
                uint256 wTokenIndex = SeriesLibrary.wTokenIndex(seriesId);

                // Get wToken balance excluding locked tokens
                uint256 wTokenBalance = erc1155Controller.balanceOf(
                    ammAddress,
                    wTokenIndex
                ) - wTokenVault.getWTokenBalance(ammAddress, seriesId);

                // calculate the amount of collateral The AMM would receive by
                // redeeming this Series' bTokens and wTokens
                unredeemedCollateral += getRedeemableCollateral(
                    seriesId,
                    wTokenBalance
                );
            }
        }

        return unredeemedCollateral;
    }

    /// @notice Calculate sale value of pro-rata LP b/wTokens in units of collateral token
    function getOptionTokensSaleValue(
        uint256 lpTokenAmount,
        uint256 lpTokenSupply,
        uint64[] memory openSeries,
        address ammAddress,
        uint256 collateralTokenBalance,
        uint256 impliedVolatility
    ) public view override returns (uint256) {
        if (lpTokenAmount == 0) return 0;
        if (lpTokenSupply == 0) return 0;

        IWTokenVault wTokenVault = IWTokenVault(
            addressesProvider.getWTokenVault()
        );

        // Calculate the amount of collateral receivable by redeeming all the expired option tokens
        uint256 expiredOptionTokenCollateral = getCollateralValueOfAllExpiredOptionTokens(
                openSeries,
                ammAddress
            );

        // Calculate amount of collateral left in the pool to sell tokens to
        uint256 totalCollateral = expiredOptionTokenCollateral +
            collateralTokenBalance;

        // Subtract pro-rata collateral amount to be withdrawn
        totalCollateral =
            (totalCollateral * (lpTokenSupply - lpTokenAmount)) /
            lpTokenSupply;

        // Given remaining collateral calculate how much all tokens can be sold for
        uint256 collateralLeft = totalCollateral;
        for (uint256 i = 0; i < openSeries.length; i++) {
            uint64 seriesId = openSeries[i];

            if (
                seriesController.state(seriesId) ==
                ISeriesController.SeriesState.OPEN
            ) {
                // Get wToken balance excluding locked tokens
                uint256 wTokenToSell = ((erc1155Controller.balanceOf(
                    ammAddress,
                    SeriesLibrary.wTokenIndex(seriesId)
                ) - wTokenVault.getWTokenBalance(ammAddress, seriesId)) *
                    lpTokenAmount) / lpTokenSupply;

                uint256 bTokenPrice = getPriceForSeries(
                    seriesId,
                    impliedVolatility
                );

                uint256 collateralAmountW = optionTokenGetCollateralOut(
                    seriesId,
                    ammAddress,
                    wTokenToSell,
                    collateralLeft,
                    bTokenPrice,
                    false
                );
                collateralLeft -= collateralAmountW;
            }
        }

        return totalCollateral - collateralLeft;
    }

    /// @notice Get the bToken price for given Series, in units of the collateral token
    /// and normalized to 1e18. We use a normalization factor of 1e18 because we need
    /// to represent fractional values, yet Solidity does not support floating point numerics.
    /// @notice For example, if this is a WBTC Call option pool and so
    /// the collateral token is WBTC, then a return value of 0.5e18 means X units of bToken
    /// have a price of 0.5 * X units of WBTC. Another example; if this were a WBTC Put
    /// option pool, and so the collateral token is USDC, then a return value of 0.1e18 means
    /// X units of bToken have a price of 0.1 * X * strikePrice units of USDC.
    /// @notice This value will always be between 0 and 1e18, so you can think of it as
    /// representing the price as a fraction of 1 collateral token unit
    /// @dev This function assumes that it will only be called on an OPEN Series; if the
    /// Series is EXPIRED, then the expirationDate - block.timestamp will throw an underflow error
    function getPriceForSeries(uint64 seriesId, uint256 annualVolatility)
        public
        view
        override
        returns (uint256)
    {
        ISeriesController.Series memory series = seriesController.series(
            seriesId
        );
        uint256 underlyingPrice = IPriceOracle(
            addressesProvider.getPriceOracle()
        ).getCurrentPrice(
                seriesController.underlyingToken(seriesId),
                seriesController.priceToken(seriesId)
            );

        return
            getPriceForSeriesInternal(
                series,
                underlyingPrice,
                annualVolatility
            );
    }

    function getPriceForSeriesInternal(
        ISeriesController.Series memory series,
        uint256 underlyingPrice,
        uint256 annualVolatility
    ) private view returns (uint256) {
        // Note! This function assumes the underlyingPrice is a valid series
        // price in units of underlyingToken/priceToken. If the onchain price
        // oracle's value were to drift from the true series price, then the bToken price
        // we calculate here would also drift, and will result in undefined
        // behavior for any functions which call getPriceForSeriesInternal
        (uint256 call, uint256 put) = IBlackScholes(
            addressesProvider.getBlackScholes()
        ).optionPrices(
                series.expirationDate - block.timestamp,
                annualVolatility,
                underlyingPrice,
                series.strikePrice,
                0
            );
        if (series.isPutOption == true) {
            return put;
        } else {
            return call;
        }
    }

    /// Get value of all assets in the pool in units of this AMM's collateralToken.
    /// Can specify whether to include the value of expired unclaimed tokens
    function getTotalPoolValue(
        bool includeUnclaimed,
        uint64[] memory openSeries,
        uint256 collateralBalance,
        address ammAddress,
        uint256 impliedVolatility
    ) public view override returns (uint256) {
        // Note! This function assumes the underlyingPrice is a valid series
        // price in units of underlyingToken/priceToken. If the onchain price
        // oracle's value were to drift from the true series price, then the bToken price
        // we calculate here would also drift, and will result in undefined
        // behavior for any functions which call getTotalPoolValue
        uint256 underlyingPrice;
        if (openSeries.length > 0) {
            // we assume the openSeries are all from the same AMM, and thus all its Series
            // use the same underlying and price tokens, so we can arbitrarily choose the first
            // when fetching the necessary token addresses
            underlyingPrice = IPriceOracle(addressesProvider.getPriceOracle())
                .getCurrentPrice(
                    seriesController.underlyingToken(openSeries[0]),
                    seriesController.priceToken(openSeries[0])
                );
        }

        IWTokenVault wTokenVault = IWTokenVault(
            addressesProvider.getWTokenVault()
        );

        // First, determine the value of all residual b/wTokens
        uint256 activeTokensValue = 0;
        uint256 expiredTokensValue = 0;
        for (uint256 i = 0; i < openSeries.length; i++) {
            uint64 seriesId = openSeries[i];
            ISeriesController.Series memory series = seriesController.series(
                seriesId
            );

            // Get wToken balance excluding locked tokens
            uint256 wTokenBalance = erc1155Controller.balanceOf(
                ammAddress,
                SeriesLibrary.wTokenIndex(seriesId)
            ) - wTokenVault.getWTokenBalance(ammAddress, seriesId);

            if (
                seriesController.state(seriesId) ==
                ISeriesController.SeriesState.OPEN
            ) {
                // value all active bTokens and wTokens at current prices
                uint256 bPrice = getPriceForSeriesInternal(
                    series,
                    underlyingPrice,
                    impliedVolatility
                );
                // wPrice = 1 - bPrice
                uint256 lockedUnderlyingValue = 1e18;
                if (series.isPutOption) {
                    lockedUnderlyingValue =
                        (lockedUnderlyingValue * series.strikePrice) /
                        underlyingPrice;
                }

                // uint256 wPrice = lockedUnderlyingValue - bPrice;
                uint256 tokensValueCollateral = seriesController
                    .getCollateralPerUnderlying(
                        seriesId,
                        wTokenBalance * (lockedUnderlyingValue - bPrice),
                        underlyingPrice
                    ) / 1e18;

                activeTokensValue += tokensValueCollateral;
            } else if (
                includeUnclaimed &&
                seriesController.state(seriesId) ==
                ISeriesController.SeriesState.EXPIRED
            ) {
                // Get collateral token locked in the series
                expiredTokensValue += getRedeemableCollateral(
                    seriesId,
                    wTokenBalance
                );
            }
        }

        // Add value of OPEN Series, EXPIRED Series, and collateral token
        return activeTokensValue + expiredTokensValue + collateralBalance;
    }

    // View functions for front-end //

    /// Get value of all assets in the pool in units of this AMM's collateralToken.
    /// Can specify whether to include the value of expired unclaimed tokens
    function getTotalPoolValueView(address ammAddress, bool includeUnclaimed)
        external
        view
        override
        returns (uint256)
    {
        IMinterAmm amm = IMinterAmm(ammAddress);

        return
            getTotalPoolValue(
                includeUnclaimed,
                amm.getAllSeries(),
                amm.collateralBalance(),
                ammAddress,
                amm.getBaselineVolatility()
            );
    }

    /// @notice Calculate premium (i.e. the option price) to buy bTokenAmount bTokens for the
    /// given Series
    /// @notice The premium depends on the amount of collateral token in the pool, the reserves
    /// of bToken and wToken in the pool, and the current series price of the underlying
    /// @param seriesId The ID of the Series to buy bToken on
    /// @param bTokenAmount The amount of bToken to buy, which uses the same decimals as
    /// the underlying ERC20 token
    /// @return The amount of collateral token necessary to buy bTokenAmount worth of bTokens
    /// NOTE: This returns the collateral + fee amount
    function bTokenGetCollateralInView(
        address ammAddress,
        uint64 seriesId,
        uint256 bTokenAmount
    ) external view override returns (uint256) {
        IMinterAmm amm = IMinterAmm(ammAddress);

        uint256 collateralWithoutFees = bTokenGetCollateralIn(
            seriesId,
            ammAddress,
            bTokenAmount,
            amm.collateralBalance(),
            getPriceForSeries(seriesId, amm.getVolatility(seriesId))
        );
        uint256 tradeFee = amm.calculateFees(
            bTokenAmount,
            collateralWithoutFees
        );
        return collateralWithoutFees + tradeFee;
    }

    /// @notice Calculate the amount of collateral token the user will receive for selling
    /// bTokenAmount worth of bToken to the pool. This is the option's sell price
    /// @notice The sell price depends on the amount of collateral token in the pool, the reserves
    /// of bToken and wToken in the pool, and the current series price of the underlying
    /// @param seriesId The ID of the Series to sell bToken on
    /// @param bTokenAmount The amount of bToken to sell, which uses the same decimals as
    /// the underlying ERC20 token
    /// @return The amount of collateral token the user will receive upon selling bTokenAmount of
    /// bTokens to the pool minus any trade fees
    /// NOTE: This returns the collateral - fee amount
    function bTokenGetCollateralOutView(
        address ammAddress,
        uint64 seriesId,
        uint256 bTokenAmount
    ) external view override returns (uint256) {
        IMinterAmm amm = IMinterAmm(ammAddress);

        uint256 collateralWithoutFees = optionTokenGetCollateralOut(
            seriesId,
            ammAddress,
            bTokenAmount,
            amm.collateralBalance(),
            getPriceForSeries(seriesId, amm.getVolatility(seriesId)),
            true
        );

        uint256 tradeFee = amm.calculateFees(
            bTokenAmount,
            collateralWithoutFees
        );
        return collateralWithoutFees - tradeFee;
    }

    /// @notice Calculate amount of collateral in exchange for selling wTokens
    function wTokenGetCollateralOutView(
        address ammAddress,
        uint64 seriesId,
        uint256 wTokenAmount
    ) external view override returns (uint256) {
        IMinterAmm amm = IMinterAmm(ammAddress);

        return
            optionTokenGetCollateralOut(
                seriesId,
                ammAddress,
                wTokenAmount,
                amm.collateralBalance(),
                getPriceForSeries(seriesId, amm.getVolatility(seriesId)),
                false
            );
    }

    /// @notice Calculate the amount of collateral the AMM would received if all of the
    /// expired Series' wTokens and bTokens were to be redeemed for their underlying collateral
    /// value
    /// @return The amount of collateral token the AMM would receive if it were to exercise/claim
    /// all expired bTokens/wTokens
    function getCollateralValueOfAllExpiredOptionTokensView(address ammAddress)
        external
        view
        override
        returns (uint256)
    {
        IMinterAmm amm = IMinterAmm(ammAddress);

        return
            getCollateralValueOfAllExpiredOptionTokens(
                amm.getAllSeries(),
                ammAddress
            );
    }

    /// @notice Calculate sale value of pro-rata LP wTokens in units of collateral token
    function getOptionTokensSaleValueView(
        address ammAddress,
        uint256 lpTokenAmount
    ) external view override returns (uint256) {
        IMinterAmm amm = IMinterAmm(ammAddress);

        uint256 lpTokenSupply = IERC20Lib(address(amm.lpToken())).totalSupply();

        return
            getOptionTokensSaleValue(
                lpTokenAmount,
                lpTokenSupply,
                amm.getAllSeries(),
                ammAddress,
                amm.collateralBalance(),
                amm.getBaselineVolatility()
            );
    }
}

// SPDX-License-Identifier: MIT

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

interface IAmmDataProvider {
    function getVirtualReserves(
        uint64 seriesId,
        address ammAddress,
        uint256 collateralTokenBalance,
        uint256 bTokenPrice
    ) external view returns (uint256, uint256);

    function bTokenGetCollateralIn(
        uint64 seriesId,
        address ammAddress,
        uint256 bTokenAmount,
        uint256 collateralTokenBalance,
        uint256 bTokenPrice
    ) external view returns (uint256);

    function optionTokenGetCollateralOut(
        uint64 seriesId,
        address ammAddress,
        uint256 optionTokenAmount,
        uint256 collateralTokenBalance,
        uint256 bTokenPrice,
        bool isBToken
    ) external view returns (uint256);

    function getCollateralValueOfAllExpiredOptionTokens(
        uint64[] memory openSeries,
        address ammAddress
    ) external view returns (uint256);

    function getOptionTokensSaleValue(
        uint256 lpTokenAmount,
        uint256 lpTokenSupply,
        uint64[] memory openSeries,
        address ammAddress,
        uint256 collateralTokenBalance,
        uint256 impliedVolatility
    ) external view returns (uint256);

    function getPriceForSeries(uint64 seriesId, uint256 annualVolatility)
        external
        view
        returns (uint256);

    function getTotalPoolValue(
        bool includeUnclaimed,
        uint64[] memory openSeries,
        uint256 collateralBalance,
        address ammAddress,
        uint256 impliedVolatility
    ) external view returns (uint256);

    function getRedeemableCollateral(uint64 seriesId, uint256 wTokenBalance)
        external
        view
        returns (uint256);

    function getTotalPoolValueView(address ammAddress, bool includeUnclaimed)
        external
        view
        returns (uint256);

    function bTokenGetCollateralInView(
        address ammAddress,
        uint64 seriesId,
        uint256 bTokenAmount
    ) external view returns (uint256);

    function bTokenGetCollateralOutView(
        address ammAddress,
        uint64 seriesId,
        uint256 bTokenAmount
    ) external view returns (uint256);

    function wTokenGetCollateralOutView(
        address ammAddress,
        uint64 seriesId,
        uint256 wTokenAmount
    ) external view returns (uint256);

    function getCollateralValueOfAllExpiredOptionTokensView(address ammAddress)
        external
        view
        returns (uint256);

    function getOptionTokensSaleValueView(
        address ammAddress,
        uint256 lpTokenAmount
    ) external view returns (uint256);
}

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../token/ISimpleToken.sol";
import "../series/ISeriesController.sol";
import "../configuration/IAddressesProvider.sol";

interface IMinterAmm {
    function lpToken() external view returns (ISimpleToken);

    function underlyingToken() external view returns (IERC20);

    function priceToken() external view returns (IERC20);

    function collateralToken() external view returns (IERC20);

    function initialize(
        ISeriesController _seriesController,
        IAddressesProvider _addressesProvider,
        IERC20 _underlyingToken,
        IERC20 _priceToken,
        IERC20 _collateralToken,
        ISimpleToken _lpToken,
        uint16 _tradeFeeBasisPoints
    ) external;

    function bTokenBuy(
        uint64 seriesId,
        uint256 bTokenAmount,
        uint256 collateralMaximum
    ) external returns (uint256);

    function bTokenSell(
        uint64 seriesId,
        uint256 bTokenAmount,
        uint256 collateralMinimum
    ) external returns (uint256);

    function addSeries(uint64 _seriesId) external;

    function getAllSeries() external view returns (uint64[] memory);

    function getVolatility(uint64 _seriesId) external view returns (uint256);

    function getBaselineVolatility() external view returns (uint256);

    function calculateFees(uint256 bTokenAmount, uint256 collateralAmount)
        external
        view
        returns (uint256);

    function updateAddressesProvider(address _addressesProvider) external;

    function getCurrentUnderlyingPrice() external view returns (uint256);

    function collateralBalance() external view returns (uint256);

    function setAmmConfig(
        int256 _ivShift,
        bool _dynamicIvEnabled,
        uint16 _ivDriftRate
    ) external;

    function claimAllExpiredTokens() external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

/** Dead simple interface for the ERC20 methods that aren't in the standard interface
 */
interface IERC20Lib {
    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

/**
 @title ISeriesController
 @author The Siren Devs
 @notice Onchain options protocol for minting, exercising, and claiming calls and puts
 @notice Manages the lifecycle of individual Series
 @dev The id's for bTokens and wTokens on the same Series are consecutive uints
 */
interface ISeriesController {
    /// @notice The basis points to use for fees on the various SeriesController functions,
    /// in units of basis points (1 basis point = 0.01%)
    struct Fees {
        address feeReceiver;
        uint16 exerciseFeeBasisPoints;
        uint16 closeFeeBasisPoints;
        uint16 claimFeeBasisPoints;
    }

    struct Tokens {
        address underlyingToken;
        address priceToken;
        address collateralToken;
    }

    /// @notice All data pertaining to an individual series
    struct Series {
        uint40 expirationDate;
        bool isPutOption;
        ISeriesController.Tokens tokens;
        uint256 strikePrice;
    }

    /// @notice All possible states a Series can be in with regard to its expiration date
    enum SeriesState {
        /**
         * New option token cans be created.
         * Existing positions can be closed.
         * bTokens cannot be exercised
         * wTokens cannot be claimed
         */
        OPEN,
        /**
         * No new options can be created
         * Positions cannot be closed
         * bTokens can be exercised
         * wTokens can be claimed
         */
        EXPIRED
    }

    /** Enum to track Fee Events */
    enum FeeType {
        EXERCISE_FEE,
        CLOSE_FEE,
        CLAIM_FEE
    }

    ///////////////////// EVENTS /////////////////////

    /// @notice Emitted when the owner creates a new series
    event SeriesCreated(
        uint64 seriesId,
        Tokens tokens,
        address[] restrictedMinters,
        uint256 strikePrice,
        uint40 expirationDate,
        bool isPutOption
    );

    /// @notice Emitted when the SeriesController gets initialized
    event SeriesControllerInitialized(
        address priceOracle,
        address vault,
        address erc1155Controller,
        Fees fees
    );

    /// @notice Emitted when SeriesController.mintOptions is called, and wToken + bToken are minted
    event OptionMinted(
        address minter,
        uint64 seriesId,
        uint256 optionTokenAmount,
        uint256 wTokenTotalSupply,
        uint256 bTokenTotalSupply
    );

    /// @notice Emitted when either the SeriesController transfers ERC20 funds to the SeriesVault,
    /// or the SeriesController transfers funds from the SeriesVault to a recipient
    event ERC20VaultTransferIn(address sender, uint64 seriesId, uint256 amount);
    event ERC20VaultTransferOut(
        address recipient,
        uint64 seriesId,
        uint256 amount
    );

    event FeePaid(
        FeeType indexed feeType,
        address indexed token,
        uint256 value
    );

    /** Emitted when a bToken is exercised for collateral */
    event OptionExercised(
        address indexed redeemer,
        uint64 seriesId,
        uint256 optionTokenAmount,
        uint256 wTokenTotalSupply,
        uint256 bTokenTotalSupply,
        uint256 collateralAmount
    );

    /** Emitted when a wToken is redeemed after expiration */
    event CollateralClaimed(
        address indexed redeemer,
        uint64 seriesId,
        uint256 optionTokenAmount,
        uint256 wTokenTotalSupply,
        uint256 bTokenTotalSupply,
        uint256 collateralAmount
    );

    /** Emitted when an equal amount of wToken and bToken is redeemed for original collateral */
    event OptionClosed(
        address indexed redeemer,
        uint64 seriesId,
        uint256 optionTokenAmount,
        uint256 wTokenTotalSupply,
        uint256 bTokenTotalSupply,
        uint256 collateralAmount
    );

    /** Emitted when the owner adds new allowed expirations */
    event AllowedExpirationUpdated(uint256 newAllowedExpiration);

    ///////////////////// VIEW/PURE FUNCTIONS /////////////////////

    function priceDecimals() external view returns (uint8);

    function erc1155Controller() external view returns (address);

    function allowedExpirationsList(uint256 expirationId)
        external
        view
        returns (uint256);

    function allowedExpirationsMap(uint256 expirationTimestamp)
        external
        view
        returns (uint256);

    function getExpirationIdRange() external view returns (uint256, uint256);

    function series(uint256 seriesId)
        external
        view
        returns (ISeriesController.Series memory);

    function state(uint64 _seriesId) external view returns (SeriesState);

    function calculateFee(uint256 _amount, uint16 _basisPoints)
        external
        pure
        returns (uint256);

    function getExerciseAmount(uint64 _seriesId, uint256 _bTokenAmount)
        external
        view
        returns (uint256, uint256);

    function getClaimAmount(uint64 _seriesId, uint256 _wTokenAmount)
        external
        view
        returns (uint256, uint256);

    function seriesName(uint64 _seriesId) external view returns (string memory);

    function strikePrice(uint64 _seriesId) external view returns (uint256);

    function expirationDate(uint64 _seriesId) external view returns (uint40);

    function underlyingToken(uint64 _seriesId) external view returns (address);

    function priceToken(uint64 _seriesId) external view returns (address);

    function collateralToken(uint64 _seriesId) external view returns (address);

    function exerciseFeeBasisPoints(uint64 _seriesId)
        external
        view
        returns (uint16);

    function closeFeeBasisPoints(uint64 _seriesId)
        external
        view
        returns (uint16);

    function claimFeeBasisPoints(uint64 _seriesId)
        external
        view
        returns (uint16);

    function wTokenIndex(uint64 _seriesId) external pure returns (uint256);

    function bTokenIndex(uint64 _seriesId) external pure returns (uint256);

    function isPutOption(uint64 _seriesId) external view returns (bool);

    function getCollateralPerOptionToken(
        uint64 _seriesId,
        uint256 _optionTokenAmount
    ) external view returns (uint256);

    function getCollateralPerUnderlying(
        uint64 _seriesId,
        uint256 _underlyingAmount,
        uint256 _price
    ) external view returns (uint256);

    /// @notice Returns the amount of collateralToken held in the vault on behalf of the Series at _seriesId
    /// @param _seriesId The index of the Series in the SeriesController
    function getSeriesERC20Balance(uint64 _seriesId)
        external
        view
        returns (uint256);

    function latestIndex() external returns (uint64);

    ///////////////////// MUTATING FUNCTIONS /////////////////////

    function mintOptions(uint64 _seriesId, uint256 _optionTokenAmount) external;

    function exerciseOption(
        uint64 _seriesId,
        uint256 _bTokenAmount,
        bool _revertOtm
    ) external returns (uint256);

    function claimCollateral(uint64 _seriesId, uint256 _wTokenAmount)
        external
        returns (uint256);

    function closePosition(uint64 _seriesId, uint256 _optionTokenAmount)
        external
        returns (uint256);

    function createSeries(
        ISeriesController.Tokens calldata _tokens,
        uint256[] calldata _strikePrices,
        uint40[] calldata _expirationDates,
        address[] calldata _restrictedMinters,
        bool _isPutOption
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

interface IPriceOracle {
    struct PriceFeed {
        address underlyingToken;
        address priceToken;
        address oracle;
    }

    function getSettlementPrice(
        address underlyingToken,
        address priceToken,
        uint256 settlementDate
    ) external view returns (bool, uint256);

    function getCurrentPrice(address underlyingToken, address priceToken)
        external
        view
        returns (uint256);

    function setSettlementPrice(address underlyingToken, address priceToken)
        external;

    function setSettlementPriceForDate(
        address underlyingToken,
        address priceToken,
        uint256 date
    ) external;

    function get8amWeeklyOrDailyAligned(uint256 _timestamp)
        external
        view
        returns (uint256);

    function addTokenPair(
        address underlyingToken,
        address priceToken,
        address oracle
    ) external;

    function getPriceFeed(uint256 feedId)
        external
        view
        returns (IPriceOracle.PriceFeed memory);

    function getPriceFeedsCount() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

library SeriesLibrary {
    function wTokenIndex(uint64 _seriesId) internal pure returns (uint256) {
        return _seriesId * 2;
    }

    function bTokenIndex(uint64 _seriesId) internal pure returns (uint256) {
        return (_seriesId * 2) + 1;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

// a library for performing various math operations

library Math {
    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a < b) return a;
        return b;
    }
}

//SPDX-License-Identifier: ISC
pragma solidity >=0.5.0 <=0.8.0;
pragma experimental ABIEncoderV2;

interface IBlackScholes {
    struct PricesDeltaStdVega {
        uint256 callPrice;
        uint256 putPrice;
        int256 callDelta;
        int256 putDelta;
        uint256 stdVega;
    }

    struct PricesStdVega {
        uint256 price;
        uint256 stdVega;
    }

    function abs(int256 x) external pure returns (uint256);

    function exp(uint256 x) external pure returns (uint256);

    function exp(int256 x) external pure returns (uint256);

    function sqrt(uint256 x) external pure returns (uint256 y);

    function optionPrices(
        uint256 timeToExpirySec,
        uint256 volatilityDecimal,
        uint256 spotDecimal,
        uint256 strikeDecimal,
        int256 rateDecimal
    ) external view returns (uint256 call, uint256 put);

    function pricesDeltaStdVega(
        uint256 timeToExpirySec,
        uint256 volatilityDecimal,
        uint256 spotDecimal,
        uint256 strikeDecimal,
        int256 rateDecimal
    ) external pure returns (PricesDeltaStdVega memory);

    function pricesStdVegaInUnderlying(
        uint256 timeToExpirySec,
        uint256 volatilityDecimal,
        uint256 spotDecimal,
        uint256 strikeDecimal,
        int256 rateDecimal,
        bool isPut
    ) external pure returns (PricesStdVega memory);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.0;

/**
 * @title IAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * @author Dakra-Mystic
 **/
interface IAddressesProvider {
    event ConfigurationAdminUpdated(address indexed newAddress);
    event EmergencyAdminUpdated(address indexed newAddress);
    event PriceOracleUpdated(address indexed newAddress);
    event AmmDataProviderUpdated(address indexed newAddress);
    event SeriesControllerUpdated(address indexed newAddress);
    event LendingRateOracleUpdated(address indexed newAddress);
    event DirectBuyManagerUpdated(address indexed newAddress);
    event ProxyCreated(bytes32 id, address indexed newAddress);
    event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);
    event VolatilityOracleUpdated(address indexed newAddress);
    event BlackScholesUpdated(address indexed newAddress);
    event AirswapLightUpdated(address indexed newAddress);
    event AmmFactoryUpdated(address indexed newAddress);
    event WTokenVaultUpdated(address indexed newAddress);
    event AmmConfigUpdated(address indexed newAddress);

    function setAddress(bytes32 id, address newAddress) external;

    function getAddress(bytes32 id) external view returns (address);

    function getPriceOracle() external view returns (address);

    function setPriceOracle(address priceOracle) external;

    function getAmmDataProvider() external view returns (address);

    function setAmmDataProvider(address ammDataProvider) external;

    function getSeriesController() external view returns (address);

    function setSeriesController(address seriesController) external;

    function getVolatilityOracle() external view returns (address);

    function setVolatilityOracle(address volatilityOracle) external;

    function getBlackScholes() external view returns (address);

    function setBlackScholes(address blackScholes) external;

    function getAirswapLight() external view returns (address);

    function setAirswapLight(address airswapLight) external;

    function getAmmFactory() external view returns (address);

    function setAmmFactory(address ammFactory) external;

    function getDirectBuyManager() external view returns (address);

    function setDirectBuyManager(address directBuyManager) external;

    function getWTokenVault() external view returns (address);

    function setWTokenVault(address wTokenVault) external;
}

pragma solidity 0.8.0;

interface IWTokenVault {
    event WTokensLocked(
        address ammAddress,
        address redeemer,
        uint256 expirationDate,
        uint256 wTokenAmount,
        uint256 lpSharesMinted
    );
    event LpSharesRedeemed(
        address ammAddress,
        address redeemer,
        uint256 expirationDate,
        uint256 numShares,
        uint256 collateralAmount
    );
    event CollateralLocked(
        address ammAddress,
        uint256 expirationDate,
        uint256 collateralAmount,
        uint256 wTokenAmount
    );

    function getWTokenBalance(address poolAddress, uint64 seriesId)
        external
        view
        returns (uint256);

    function lockActiveWTokens(
        uint256 lpTokenAmount,
        uint256 lpTokenSupply,
        address redeemer,
        uint256 volatility
    ) external;

    function redeemCollateral(uint256 expirationDate, address redeemer)
        external
        returns (uint256);

    function lockCollateral(
        uint64 seriesId,
        uint256 collateralAmount,
        uint256 wTokenAmount
    ) external;

    function getLockedValue(address _ammAddress, uint256 _expirationDate)
        external
        view
        returns (uint256);

    function getRedeemableCollateral(
        address _ammAddress,
        uint256 _expirationDate
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

/** Interface for any Siren SimpleToken
 */
interface ISimpleToken {
    function initialize(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) external;

    function mint(address to, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}