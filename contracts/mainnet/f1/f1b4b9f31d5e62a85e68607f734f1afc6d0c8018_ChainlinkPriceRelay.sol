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
* File:     ChainlinkPriceRelay.sol
* Author:   Peter T. Flynn
* Location: Local
* Requires: ITokenPriceManagerMinimal.sol, AggregatorV2V3Interface.sol
* License:  Apache 2.0
******************************************************************************/

/// @title TokenPriceManager-style interface for ChainLink price aggregators
/// @author Peter T. Flynn
/// @notice Creates an interface, common with other TokenPriceManagers, which gets data from a
/// a ChainLink price aggregator
/// @dev All variables are set at creation time - both for security, and for simplicity
contract ChainlinkPriceRelay is ITokenPriceManagerMinimal {
	/// @notice The address of the ChainLink price aggregator used to 
	/// price [tokenPrimary] in [tokenDenominator]
	/// @dev The aggregator's decimal precision may vary
	AggregatorV2V3Interface public immutable chainlinkOracle;
	/// @notice The address of the token which the ChainLink price aggregator prices
	/// @dev Must match what's returned by the [chainlinkOracle]
	address private immutable tokenPrimary;
	/// @notice The address of the token which the ChainLink price aggregator
	/// prices [tokenPrimary] in (must be address(0) for USD denomination)
	/// @dev Must match what's returned by the [chainlinkOracle]
	address private immutable tokenDenominator;

	/// @notice Returned when the ChainLink price aggregator returns bad data
	error ChainlinkPriceNegative();
	/// @notice Returned when the ChainLink price aggregator returns data older than 24 hours
	error ChainlinkDataStale();

	/// @notice See respective variable comments for guidance on arguments
	constructor(
		AggregatorV2V3Interface _chainlinkOracle,
		address _tokenPrimary,
		address _tokenDenominator
	) {
		chainlinkOracle = _chainlinkOracle;
		tokenPrimary = _tokenPrimary;
		tokenDenominator = _tokenDenominator;
	}

	/// @return uint256 The price reported by ChainLink for the [tokenPrimary]
	/// (denominated in [tokenDenominator], with 18 decimals of precision)
	/// @return address The [tokenDenominator]
	/// @dev Takes in an [ITokenPriceManagerMinimal.PriceType] for compatibility with the
	/// ITokenPriceManagerMinimal interface, but it is not used here.
	function getPrice(PriceType) external view returns (uint256, address) {
		(, int256 answer,, uint256 updatedAt,) = chainlinkOracle.latestRoundData();
		if (answer <= 0) revert ChainlinkPriceNegative();
		if (updatedAt < block.timestamp - 1 days) revert ChainlinkDataStale();
		return (
			uint(answer) * (10 ** (18 - chainlinkOracle.decimals())), // Scale for 18 decimals
			tokenDenominator
		);
	}

	/// @return address The token which is being priced
	function getTokenPrimary() external view returns (address) { return tokenPrimary; }

	/// @return address The token which prices the primary token, may be address(0) to indicate USD
	function getTokenDenominator() external view returns (address) { return tokenDenominator; }
}

/*****************************************************************************/




/******************************************************************************
* File:     AggregatorInterface.sol
* Author:   SmartContract ChainLink, Ltd.
* Location: https://github.com/smartcontractkit/chainlink/blob/develop/
*			contracts/src/v0.8/interfaces/AggregatorInterface.sol
* License:  MIT
******************************************************************************/

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

/*****************************************************************************/




/******************************************************************************
* File:     AggregatorV3Interface.sol
* Author:   SmartContract ChainLink, Ltd.
* Location: https://github.com/smartcontractkit/chainlink/blob/develop/
*			contracts/src/v0.8/interfaces/AggregatorV3Interface.sol
* License:  MIT
******************************************************************************/

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

/*****************************************************************************/




/******************************************************************************
* File:     AggregatorV2V3Interface.sol
* Author:   SmartContract ChainLink, Ltd.
* Location: https://github.com/smartcontractkit/chainlink/blob/develop/
*			contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol
* Requires: AggregatorInterface.sol, AggregatorV3Interface.sol
* License:  MIT
******************************************************************************/

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

/*****************************************************************************/