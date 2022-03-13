/**
 *Submitted for verification at polygonscan.com on 2022-03-12
*/

// SPDX-License-Identifier: MIT
// dev: https://cainuriel.github.io/
pragma solidity ^0.8.7;

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

contract OracleMaticUSD {

    AggregatorV3Interface internal priceFeed;

       /**
     * Network: MOMBAI
     * Aggregator: MATIC/USD
     * Address: 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
     */
    constructor() {
        priceFeed = AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int, uint) {
        (
            /*uint80 roundID*/
                            ,
            int price,
            /*uint startedAt*/
                            ,
            /*uint timeStamp*/
            uint timeStamp,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return (price, timeStamp);
    }
        // MATIC/USD
        function getDescription() public view returns (string memory) {
    
            string memory des = priceFeed.description();
        return des;
    }
}