/**
 *Submitted for verification at polygonscan.com on 2022-04-03
*/

// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

/******************************************************************************
* File:     ITokenPriceManagerMinimal.sol
* Author:   Peter T. Flynn
* Location: Local
* License:  Apache 2.0
******************************************************************************/

/// @title Price maintainer for arbitrary tokens
/// @author Peter T. Flynn
/// @notice Maintains a common interface for requesting the price of the given token, with
/// special functionality for TokenSets.
/// @dev Contract must be initialized before use. Price should always be requested using 
/// getPrice(PriceType), rather than viewing the [price] variable. Price returned is dependent
/// on the transactor's SWD balance. Constants require adjustment for deployment outside Polygon. 
interface ITokenPriceManagerMinimal {
    // @notice Affects the application of the "spread fee" when requesting token price
    enum PriceType { BUY, SELL, RAW }
    
    /// @notice Gets the current price of the primary token, denominated in [tokenDenominator]
    /// @dev Returns a different value, depending on the SWD balance of tx.origin's wallet.
    /// If the balance is over the threshold, getPrice() will return the price unmodified,
    /// otherwise it adds the dictated fee. Tx.origin is purposefully used over msg.sender,
    /// so as to be compatible with DEx aggregators. As a side effect, this makes it incompatible
    /// with relays. Price is always returned with 18 decimals of precision, regardless of token
    /// decimals. Manual adjustment of precision must be done later for [tokenDenominator]s
    /// with less precision.
    /// @param priceType "BUY" for buying, "SELL" for selling,
    /// and "RAW" for a direct price request
    /// @return uint256 Current price in [tokenDenominator], per primary token
    /// @return address Current [tokenDenominator], may be address(0) to indicate USD
    function getPrice(PriceType priceType) external view returns (uint256, address);

    /// @return address Current [tokenPrimary]
    function getTokenPrimary() external view returns (address);

    /// @return address Current [tokenDenominator], may be address(0) to indicate USD
    function getTokenDenominator() external view returns (address);
}

/*****************************************************************************/




/******************************************************************************
* File:     CurvePoolPriceRelay.sol
* Author:   Peter T. Flynn
* Location: Local
* Requires: ITokenPriceManagerMinimal.sol
* License:  Apache 2.0
******************************************************************************/

interface CurvePool {
	function get_virtual_price() external view returns (uint);
}

interface CurveToken {
	function minter() external view returns (CurvePool);
}

/// @title TokenPriceManager-style interface for Curve LP tokens
/// @author Peter T. Flynn
/// @notice Creates an interface, common with other TokenPriceManagers, which gets data from a
/// a Curve pool, corresponding to the selected LP token
/// @dev All variables are set at creation time - both for security, and for simplicity
contract CurvePoolPriceRelay is ITokenPriceManagerMinimal {
	/// @notice The address of the token to be priced
	CurveToken private immutable tokenPrimary;
	/// @notice The address of the Curve pool used for pricing [tokenPrimary]
	CurvePool private immutable curvePool;

	/// @notice Returns when the chosen [tokenPrimary] does not use the known Curve interface
	error BadToken();
	/// @notice Returns when the Curve pool returns a [virtual_price] of 0
	error BadPrice();

	/// @notice Fetches the appropriate Curve pool used for pricing the requested [tokenPrimary]
	constructor(CurveToken _tokenPrimary) {
		tokenPrimary = _tokenPrimary;
		curvePool = _tokenPrimary.minter();
		if (address(curvePool) == address(0)) revert BadToken();
		if (curvePool.get_virtual_price() == 0) revert BadPrice();
	}

	/// @return price The price reported by the Curve pool for the [tokenPrimary]
	/// (denominated in USD, with 18 decimals of precision)
	/// @return address Address(0), indicating pricing in USD, and conforming with
	/// the TokenPriceManager interface
	/// @dev Takes in an [ITokenPriceManagerMinimal.PriceType] for compatibility with the
	/// ITokenPriceManagerMinimal interface, but it is not used here.
	function getPrice(PriceType) external view returns (uint price, address) {
		price = curvePool.get_virtual_price();
		if (price == 0) revert BadPrice();
	}

    /// @return address The token which is being priced
    function getTokenPrimary() external view returns (address) { return address(tokenPrimary); }

    /// @return address Always address(0), indicating that the price is in USD,
	/// in accordance with the ITokenPriceManager interface
    function getTokenDenominator() external pure returns (address) { return address(0); }
}

/*****************************************************************************/