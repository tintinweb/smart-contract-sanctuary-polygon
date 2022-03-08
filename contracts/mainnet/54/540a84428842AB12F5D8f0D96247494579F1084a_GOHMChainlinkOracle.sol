// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "../interfaces/IOracle.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title oracle contract for gohm (ohm*index, both feed by chainlink)
 * @author Entropyfi
 */
contract GOHMChainlinkOracle is IOracle {
	uint256 constant PRICE_PRECISION = 1E8;
	uint256 constant INDEX_PRECISION = 1E9;
	address public immutable override token; // ohm token
	AggregatorV3Interface public immutable ohmPriceFeed;
	AggregatorV3Interface public immutable indexFeed;

	/**
	 * @param token_ gohm
	 * @param ohmPriceFeed_ chainlink aggregator address for `ohm`
	 * @param indexFeed_ chainlink aggregator address for `ohm index`
	 */
	constructor(
		address token_,
		address ohmPriceFeed_,
		address indexFeed_
	) {
		// 1. token (gohm)
		require(token_ != address(0), "CO:ZR ADDR");
		token = token_;

		// 2. ohm price feed
		AggregatorV3Interface(ohmPriceFeed_).latestRoundData(); // check
		ohmPriceFeed = AggregatorV3Interface(ohmPriceFeed_);

		// 3. ohm index
		AggregatorV3Interface(indexFeed_).latestRoundData(); // check
		indexFeed = AggregatorV3Interface(indexFeed_);
	}

	function query() external view override returns (uint256 gohmPrice_) {
		(, int256 price, , , ) = ohmPriceFeed.latestRoundData();
		(, int256 index, , , ) = indexFeed.latestRoundData();

		gohmPrice_ = uint256(price * index) / INDEX_PRECISION;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface IOracle {
	function query() external view returns (uint256 price_);

	function token() external view returns (address token_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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