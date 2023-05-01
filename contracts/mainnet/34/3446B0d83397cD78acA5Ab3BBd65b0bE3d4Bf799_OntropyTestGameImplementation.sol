/**
 *Submitted for verification at polygonscan.com on 2023-05-01
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract OntropyTestGameImplementation {
    event GameResultBatchEvent(
        string[] gameIds,
        uint32[] results,
        bytes signature
    );

    struct GameResult {
        string gameId;
        uint32 result;
    }

    function postResultsBatch(GameResult[] memory games, bytes memory signature) public {
        string[] memory gameIds = new string[](games.length);
        uint32[] memory results = new uint32[](games.length);

        for (uint i = 0; i < games.length; i++) {
            gameIds[i] = games[i].gameId;
            results[i] = games[i].result;
        }

        emit GameResultBatchEvent(gameIds, results, signature);
    }
}