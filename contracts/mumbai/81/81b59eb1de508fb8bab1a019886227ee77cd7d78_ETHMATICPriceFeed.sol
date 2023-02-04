/**
 *Submitted for verification at polygonscan.com on 2023-02-03
*/

// SPDX-License-Identifier: MIT


// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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

// File: contracts/DETH_DMATIC_FEED.sol


pragma solidity ^0.8.7;


contract ETHMATICPriceFeed {
    AggregatorV3Interface internal ethPriceFeed;
    AggregatorV3Interface internal maticPriceFeed;

    /**
     * Network: Polygon
     * Aggregator: ETH/USD
     * Address: 0x0715A7794a1dc8e42615F059dD6e406A6594651A
     */
    constructor() {
        ethPriceFeed = AggregatorV3Interface(
            0x0715A7794a1dc8e42615F059dD6e406A6594651A
        );
        maticPriceFeed = AggregatorV3Interface(
            0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
        );
    }

    /**
     * Returns the latest ETH/USD price.
     */
    function getETHUSDPrice() public view returns (int) {
        (
            /* uint80 roundID */,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = ethPriceFeed.latestRoundData();
        return price;
    }

    /**
     * Returns the latest MATIC/USD price.
     */
    function getMATICUSDPrice() public view returns (int) {
        (
            /* uint80 roundID */,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = maticPriceFeed.latestRoundData();
        return price;
    }

    /**
     * Returns the latest ETH/MATIC price.
     */
    function getETHMATICPrice() public view returns (int) {
        int ethPrice = getETHUSDPrice();
        int maticPrice = getMATICUSDPrice();
        return ethPrice / maticPrice;
    }
}