// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
//TODO: Add a proper dPoR with working authorization.

contract dPoR {
    uint256 public constant version = 0;

    uint8 public decimals;
    uint256 public latestAnswer;
    uint256 public latestTimestamp;
    uint256 public latestRound;

    mapping(uint256 => uint256) public getAnswer;
    mapping(uint256 => uint256) public getTimestamp;
    mapping(uint256 => uint256) private getStartedAt;

    constructor(uint8 _decimals, uint256 _initialAnswer) {
        decimals = _decimals;
        increase(_initialAnswer);
    }

    function increase(uint256 _amount) public {
        latestAnswer = latestAnswer + _amount;
        latestTimestamp = block.timestamp;
        latestRound++;
        getAnswer[latestRound] = latestAnswer;
        getTimestamp[latestRound] = block.timestamp;
        getStartedAt[latestRound] = block.timestamp;
    }

    function decrease(uint256 _amount) public {
        latestAnswer = latestAnswer - _amount;
        latestTimestamp = block.timestamp;
        latestRound++;
        getAnswer[latestRound] = latestAnswer;
        getTimestamp[latestRound] = block.timestamp;
        getStartedAt[latestRound] = block.timestamp;
    }

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            uint256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (
            _roundId,
            getAnswer[_roundId],
            getStartedAt[_roundId],
            getTimestamp[_roundId],
            _roundId
        );
    }

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            uint256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (
            uint80(latestRound),
            getAnswer[latestRound],
            getStartedAt[latestRound],
            getTimestamp[latestRound],
            uint80(latestRound)
        );
    }

    function description() external pure returns (string memory) {
        return "/dPoR.sol";
    }
}