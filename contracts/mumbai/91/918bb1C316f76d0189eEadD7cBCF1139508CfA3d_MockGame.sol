/**
 *Submitted for verification at polygonscan.com on 2022-09-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// Your game contract must implement this interface to be compatible
// with SwissTournamentManager (created via the factory)
interface IMatchResolver {
    // Given two player IDs, return the ID of the winner
    // Cannot return 0
    function matchup(uint64 player0, uint64 player1) external view returns (uint64);
}

/// @title Demo Game
/// @author @saucepoint <[email protected]>
/// @notice Demonstrate how an on-chain game can faciliate a Swiss Tournament
/// @notice You can manage player data here, but just note that Swiss Tournament
///         will manage the matchups. It tracks players as uint256 (starting at 1. playerId=0 is not allowed)
/// @notice In order of MockGame to be compatible with SwissTournamentManager, it needs to implement IMatchResolver interface
contract MockGame is IMatchResolver {
    function playerScore(uint64 playerId) public pure returns (uint64) {
        return uint64(bytes8(keccak256(abi.encodePacked(playerId))));
    }

    // the larger hash of a player's id is the winner
    function matchup(uint64 player0, uint64 player1) public pure returns (uint64){
        return playerScore(player0) < playerScore(player1) ? player1 : player0;
    }
}