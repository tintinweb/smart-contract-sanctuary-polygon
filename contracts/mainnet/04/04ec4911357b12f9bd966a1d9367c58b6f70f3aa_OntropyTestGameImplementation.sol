// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract OntropyTestGameImplementation is Ownable {
    uint constant MAX_GAME_ID_LENGTH = 50;
    uint constant MAX_BYTES_LENGTH = 33;

    event GameResultEvent(
        string gameId,
        bytes[][] Bs,
        bytes[][] fs,
        uint32 result
    );

    struct GameResult {
        string gameId;
        bytes[][] Bs;
        bytes[][] fs;
        uint32 result;
    }

    function postResults(
        string memory gameId,
        bytes[][] memory Bs,
        bytes[][] memory fs,
        uint32 result
    ) public {
        require(bytes(gameId).length <= MAX_GAME_ID_LENGTH, "Game ID too long");
        require(Bs.length <= 10 && fs.length <= 10, "Arrays too big");

        for (uint i = 0; i < Bs.length; i++) {
            require(Bs[i].length <= 10, "Array inside Bs too big");
            for (uint j = 0; j < Bs[i].length; j++) {
                require(Bs[i][j].length <= MAX_BYTES_LENGTH, "Bytes inside Bs too long");
            }
        }

        for (uint i = 0; i < fs.length; i++) {
            require(fs[i].length <= 10, "Array inside fs too big");
            for (uint j = 0; j < fs[i].length; j++) {
                require(fs[i][j].length <= MAX_BYTES_LENGTH, "Bytes inside fs too long");
            }
        }

        emit GameResultEvent(gameId, Bs, fs, result);
    }

    function postResultsBatch(GameResult[] memory games) public {
        require(games.length <= 10, "Cannot upload more than 10 game results at once");

        for (uint i = 0; i < games.length; i++) {
            postResults(games[i].gameId, games[i].Bs, games[i].fs, games[i].result);
        }
    }
}