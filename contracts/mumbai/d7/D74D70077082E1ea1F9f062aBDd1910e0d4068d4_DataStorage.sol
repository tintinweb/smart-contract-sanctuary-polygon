// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./AggregatorV3Interface.sol";

contract DataStorage {
    AggregatorV3Interface dataFeed;

    struct Answer {
        uint80 roundId;
        int256 answer;
        uint256 startedAt;
        uint256 updatedAt;
        uint80 answeredInRound;
        bool exists;
    }

    mapping(uint256 => Answer) data;
    uint256 public dataCount;

    Answer public latestData;

    event NewPrice(uint256 indexed roundId);

    constructor(address _dataFeedAddress) {
        dataFeed = AggregatorV3Interface(_dataFeedAddress);
    }

    function getData(uint256 timestamp) public view returns (uint80, int256, uint256, uint256, uint80) {
        while (!data[timestamp].exists) {
            timestamp--;
        }
        Answer memory result = data[timestamp];
        return (result.roundId, result.answer, result.startedAt, result.updatedAt, result.answeredInRound);
    }

    function saveRound(uint80 _roundId) public returns (uint256) {
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            dataFeed.getRoundData(_roundId);
        Answer memory result = Answer(roundId, answer, startedAt, updatedAt, answeredInRound, true);
        if (data[startedAt].exists) {
            return startedAt;
        }
        dataCount++;
        data[startedAt] = result;
        if (latestData.startedAt < result.startedAt) {
            latestData = result;
            emit NewPrice(roundId);
        }
        return startedAt;
    }

    function saveLatestRound() public returns (uint256) {
        (uint80 roundId,,,,) = dataFeed.latestRoundData();
        return saveRound(roundId);
    }

    function fillHistory(uint80 _roundId, uint256 count) public {
        (uint16 phaseId, uint64 aggregatorRoundId) = parseIds(_roundId);
        for (uint64 i = 0; i < count; i++) {
            uint80 newRoundId = addPhase(phaseId, aggregatorRoundId - i);
            saveRound(newRoundId);
        }
    }

    function addPhase(uint16 _phase, uint64 _originalId) internal pure returns (uint80) {
        return uint80((uint256(_phase) << 64) | _originalId);
    }

    function parseIds(uint80 _roundId) internal pure returns (uint16, uint64) {
        uint16 phaseId = uint16(_roundId >> 64);
        uint64 aggregatorRoundId = uint64(_roundId);
        return (phaseId, aggregatorRoundId);
    }
}