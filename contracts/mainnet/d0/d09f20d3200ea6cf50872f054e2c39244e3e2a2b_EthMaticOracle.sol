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

contract EthMaticOracle {
    // is IChainlinkOracle

    AggregatorV3Interface internal maticEthPriceFeed;

    constructor(address _maticEthPriceFeed) {
        maticEthPriceFeed = AggregatorV3Interface(_maticEthPriceFeed);
    }

    function getPrice() public view returns (int256) {
        (
            /* uint80 roundID */,
            int256 maticEth,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = maticEthPriceFeed.latestRoundData();

        // Assumption is MATIC-ETH price (and the getPrice() answer) is given to 18 decimals
        return int(10 ** 36) / maticEth;
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