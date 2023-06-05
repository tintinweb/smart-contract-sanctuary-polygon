// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract DaiMaticOracle {
    // is IChainlinkOracle

    AggregatorV3Interface internal daiUsdPriceFeed;
    AggregatorV3Interface internal maticUsdPriceFeed;

    constructor(address _daiUsdPriceFeed, address _maticUsdPriceFeed) {
        daiUsdPriceFeed = AggregatorV3Interface(_daiUsdPriceFeed);
        maticUsdPriceFeed = AggregatorV3Interface(_maticUsdPriceFeed);
    }

    function getPrice() public view returns (int256) {
        (
            /* uint80 roundID */,
            int256 daiUsd,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = daiUsdPriceFeed.latestRoundData();

        (
            /* uint80 roundID */,
            int256 maticUsd,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = maticUsdPriceFeed.latestRoundData();

        // Assumption here is DAI-USD and MATIC-USD prices have the same amount of decimal
        // places and that DAI-MATIC price should be given to 18 decimals
        return daiUsd * int(10 ** 18) / maticUsd;
    }

    function latestAnswer() external view returns (int256) {
        return this.getPrice();
    }

    function getAnswer(uint256) external view returns (int256) {
        return this.getPrice();
    }

    // Maintain compatibility with aztec-connect mocks
    function latestRound() external view returns (uint80, int256, uint256, uint256, uint80) {
        return (
            uint80(1), // roundId
            this.getPrice(), // answer
            block.timestamp - 1, // startedAt
            block.timestamp, // updatedAt
            uint80(1) // answeredInRound
        );
    }

    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80) {
        return this.latestRound();
    }

    function getRoundData(uint256) external view returns (uint80, int256, uint256, uint256, uint80) {
        return this.latestRound();
    }
}