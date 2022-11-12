// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract AggregatorV3Fake is AggregatorV3Interface {
    struct RoundData {
        uint80 roundId;
        int256 answer;
        uint256 startedAt;
        uint256 updatedAt;
        uint80 answeredInRound;
    }

    constructor() {
        rounds[0] = RoundData(
            0,
            0,
            block.timestamp,
            block.timestamp,
            0
        );
    }

    int256 public lastPrice = 2313557000000;
    uint80 public nextRoundId = 1;

    mapping(uint80 => RoundData) rounds;

    function setCost(int256 _price) external {
        lastPrice = _price;
        rounds[nextRoundId] = RoundData(
            nextRoundId,
            lastPrice,
            block.timestamp,
            block.timestamp,
            nextRoundId
        );
        nextRoundId += 1;
    }

    function decimals() external pure returns (uint8) {
        return 8;
    }

    function description() external pure returns (string memory) {
        return "BNB/USD Fake Aggregator";
    }

    function version() external pure returns (uint256) {
        return 1;
    }

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
        )
    {
        return (
            rounds[_roundId].roundId,
            rounds[_roundId].answer,
            rounds[_roundId].startedAt,
            rounds[_roundId].updatedAt,
            rounds[_roundId].answeredInRound
        );
    }

    function _rand(uint256 _modulus, uint256 _offset)
        internal
        view
        returns (uint256)
    {
        return
            (uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) %
                _modulus) + _offset;
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
        return (
            rounds[nextRoundId - 1].roundId,
            rounds[nextRoundId - 1].answer,
            rounds[nextRoundId - 1].startedAt,
            rounds[nextRoundId - 1].updatedAt,
            rounds[nextRoundId - 1].answeredInRound
        );
    }
}

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