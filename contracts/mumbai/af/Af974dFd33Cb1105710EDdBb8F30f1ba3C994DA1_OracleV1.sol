// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

// References
// https://docs.chain.link/data-feeds/api-reference/#latestrounddata
// https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/tests/MockV3Aggregator.sol
contract OracleV1 {
    struct Round {
        int256 answer;
        uint256 startedAt;
        uint256 updatedAt;
    }

    event UpdateState(
        uint256 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt
    );

    uint256 public latestRoundId;
    mapping(uint256 => Round) public rounds; // roundId -> Round

    function updateState(
        uint256 _latestRoundId,
        int256 _answer,
        uint256 _startedAt,
        uint256 _updatedAt
    ) public {
        latestRoundId = _latestRoundId;
        Round memory newRound = Round({
            answer: _answer,
            startedAt: _startedAt,
            updatedAt: _updatedAt
        });
        rounds[_latestRoundId] = newRound;

        emit UpdateState(
            _latestRoundId,
            _answer,
            _startedAt,
            _updatedAt
        );
    }
}