/**
 *Submitted for verification at polygonscan.com on 2022-02-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// File: contracts/interfaces/AggregatorV3Interface.sol

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

pragma solidity ^0.7.0;



interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface
{
}


contract FeedConsumer {
  AggregatorV2V3Interface public immutable AGGREGATOR;

  constructor(address feedAddress) {
    AGGREGATOR = AggregatorV2V3Interface(feedAddress);
  }

  function latestAnswer() external view returns (int256 answer) {
    return AGGREGATOR.latestAnswer();
  }

  function latestTimestamp() external view returns (uint256) {
    return AGGREGATOR.latestTimestamp();
  }

  function latestRound() external view returns (uint256) {
    return AGGREGATOR.latestRound();
  }

  function getAnswer(uint256 roundId) external view returns (int256) {
    return AGGREGATOR.getAnswer(roundId);
  }

  function getTimestamp(uint256 roundId) external view returns (uint256) {
    return AGGREGATOR.getTimestamp(roundId);
  }

  function decimals() external view returns (uint8) {
    return AGGREGATOR.decimals();
  }

  function description() external view returns (string memory) {
    return AGGREGATOR.description();
  }

  function version() external view returns (uint256) {
    return AGGREGATOR.version();
  }

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return AGGREGATOR.getRoundData(_roundId);
  }

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return AGGREGATOR.latestRoundData();
  }
}