// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

// References
// https://docs.chain.link/data-feeds/api-reference/#latestrounddata
// https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/tests/MockV3Aggregator.sol
contract OracleV2 {
    struct Round {
        int256 answer;
        uint256 startedAt;
        uint256 updatedAt;
    }
    struct RoundArgument {
        uint256 roundId;
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

    function updateStates(RoundArgument[] memory _rounds) public {
        uint256 size = _rounds.length;
        for (uint i = 0; i < size; i++) {
            RoundArgument memory _round = _rounds[i];
            updateState(
                _round.roundId,
                _round.answer,
                _round.startedAt,
                _round.updatedAt
            );
        }
    }

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

    function debug_getRounds(uint256 from, uint256 count) public view returns(Round[] memory) {
        Round[] memory _rounds = new Round[](count);
        for (uint i = 0; i < count; i++) {
            _rounds[i] = rounds[from + i];
        }
        return _rounds;
    }

    function debug_getRoundsFromIds(uint256[] memory ids) public view returns(Round[] memory) {
        Round[] memory _rounds = new Round[](ids.length);
        for (uint i = 0; i < ids.length; i++) {
            _rounds[i] = rounds[ids[i]];
        }
        return _rounds;
    }
    
    function debug_cleanState() public {
        for (uint i = 0; i <= latestRoundId; i++) {
            delete rounds[i];
        }
        latestRoundId = 0;
    }
}