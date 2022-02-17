/**
 *Submitted for verification at polygonscan.com on 2022-02-17
*/

// File: temp_consumer.sol


pragma solidity ^0.8.7;

interface AggregatorInterface {
  function latestAnswer() external view returns (uint256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

contract MaticUSDPriceConsumer {

    AggregatorInterface internal priceFeed;

    /**
     * Network: Mumbai
     * Aggregator: MATIC/USD
     * Address: 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
     */
    constructor(address _aggregator) {
        priceFeed = AggregatorInterface(_aggregator);
    }
  
    function getLatestPrice() public view returns (uint256) {
        return priceFeed.latestAnswer();
    }

    function getLatestPriceTimestamp() public view returns (uint256) {
        return priceFeed.latestTimestamp();
    }
}