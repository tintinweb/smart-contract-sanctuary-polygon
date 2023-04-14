/**
 *Submitted for verification at polygonscan.com on 2023-04-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Tournament {
    
    struct Player {
        address name;
        uint256 score;
    }

    struct Game {
        address[] players;
        uint256 numPlayers;
        uint256 winningScore;
        uint256 endTime;
        bool ended;
        mapping(address => uint256) scores;
    }

    mapping(uint256 => Game) public games;
    uint256 public numGames;
    mapping(uint256 => Player[]) private leaderboard;


   

    // Function to create a new tournament game
    function createGame(
        uint256 numPlayers,
        uint256 winningScore,
        uint256 duration
    ) public {
        require(numPlayers > 0, "Number of players must be greater than zero");
        require(winningScore > 0, "Winning score must be greater than zero");
        require(duration > 0, "Duration must be greater than zero");

        uint256 gameId = numGames++;
        games[gameId].numPlayers = numPlayers;
        games[gameId].winningScore = winningScore;
        games[gameId].endTime = block.timestamp + duration;
    }

    // Function to join a tournament game
    function joinGame(uint256 gameId) public {
        require(gameId < numGames, "Invalid game ID");
        require(!games[gameId].ended, "Game has already ended");
        require(
            games[gameId].players.length < games[gameId].numPlayers,
            "Game is full"
        );

        games[gameId].players.push(msg.sender);
        games[gameId].scores[msg.sender] = 0;
    }

    // Function to record a player's score in a tournament game
    function recordScore(uint256 gameId, uint256 score) public {
        require(gameId < numGames, "Invalid game ID");
        require(!games[gameId].ended, "Game has already ended");
        require(
            games[gameId].scores[msg.sender] == 0,
            "Score has already been recorded for this player"
        );

        games[gameId].scores[msg.sender] = score;

        // Check if all players have recorded their scores
        // if (games[gameId].players.length == games[gameId].numPlayers) {
            // Check if the tournament game has ended
            if (block.timestamp >= games[gameId].endTime) {
                endGame(gameId);
            }
        // }
    }
    
    // Function to end a tournament game and generate a leaderboard
    function endGame(uint256 gameId) private {
        require(!games[gameId].ended, "Game has already ended");

        // Calculate scores and determine the winner, if any
        for (uint256 i = 0; i < games[gameId].players.length; i++) {
            address playerAddress = games[gameId].players[i];
            uint256 playerScore = games[gameId].scores[playerAddress];
            if (playerScore >= games[gameId].winningScore) {
                games[gameId].ended = true;
                return;
            }
            Player memory player = Player({name:playerAddress, score: playerScore});
            leaderboard[gameId].push(player);
        }

        // Sort leaderboard by descending score
        sortLeaderboard(gameId);
        games[gameId].ended = true;
    }

    // Function to retrieve the leaderboard for a tournament game
    function getLeaderboard(
        uint256 gameId
    ) public view returns (Player[] memory) {
        require(gameId < numGames, "Invalid game ID");
        require(games[gameId].ended, "Game has not yet ended");

        return leaderboard[gameId];
    }

     function CheckUserJoined(uint256 gameId)
    public view returns(address[] memory){
        return games[gameId].players;
    }


    // Function to sort the leaderboard for a tournament game by descending score
    function sortLeaderboard(uint256 gameId) private {
        uint256 numPlayers = leaderboard[gameId].length;
        for (uint256 i = 0; i < numPlayers - 1; i++) {
            for (uint256 j = i + 1; j < numPlayers; j++) {
                if (
                    leaderboard[gameId][i].score < leaderboard[gameId][j].score
                ) {
                    Player memory temp = leaderboard[gameId][i];
                    leaderboard[gameId][i] = leaderboard[gameId][j];
                    leaderboard[gameId][j] = temp;
                }
            }
        }
    }

//     function sortLeaderboard(uint256 gameId) private {
//     uint256 numPlayers = leaderboard[gameId].length;
//     for (uint256 i = 0; i < numPlayers - 1; i++) {
//         for (uint256 j = i + 1; j < numPlayers; j++) {
//             if (
//                 leaderboard[gameId][i].score < leaderboard[gameId][j].score
//             ) {
//                 // Swap players
//                 Player memory temp = leaderboard[gameId][i];
//                 leaderboard[gameId][i] = leaderboard[gameId][j];
//                 leaderboard[gameId][j] = temp;
                
//                 // Swap player addresses
//                 address tempAddress = games[gameId].players[i];
//                 games[gameId].players[i] = games[gameId].players[j];
//                 games[gameId].players[j] = tempAddress;
//             }
//         }
//     }
// }

}