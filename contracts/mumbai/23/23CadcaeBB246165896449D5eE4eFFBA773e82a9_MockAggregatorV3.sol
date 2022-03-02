// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "AggregatorV3Interface.sol";

struct RoundData {
    uint80 roundId;
    int256 answer;
    uint256 startedAt;
    uint256 updatedAt;
    uint80 answeredInRound;
}

contract MockAggregatorV3 is AggregatorV3Interface {
    uint8 public decimals;
    string public description;
    uint256 public version = 3;
    RoundData public latestRoundData;

    constructor(
        uint8 _decimals,
        string memory _description,
        int256 _answer
    ) {
        decimals = _decimals;
        description = _description;
        updatePrice(_answer);
    }

    function updatePrice(int256 _answer) public {
        latestRoundData.answer = _answer;
        latestRoundData.roundId++;
        latestRoundData.answeredInRound++;
        latestRoundData.startedAt = block.timestamp;
        latestRoundData.updatedAt = block.timestamp;
    }

    function getRoundData(uint80) external view returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    ) {
        roundId = latestRoundData.roundId;
        answer = latestRoundData.answer;
        startedAt = latestRoundData.startedAt;
        updatedAt = latestRoundData.updatedAt;
        answeredInRound = latestRoundData.answeredInRound;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

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