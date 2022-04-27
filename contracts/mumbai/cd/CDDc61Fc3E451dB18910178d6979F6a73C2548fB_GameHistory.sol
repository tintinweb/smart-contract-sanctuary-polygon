/**
 *Submitted for verification at polygonscan.com on 2022-04-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title GameHistory
 * @dev Save & Retrieve Played Games
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract GameHistory {

    /**
     * @dev Game struct
     * @param roomName name of game room
     * @param playerName name of winning player
     * @param score score of winning player
     */
    struct Game {
        string roomName;
        string winningPlayerName;
        uint256 winningScore;
    }

    /**
     * @dev Game History
     */
    Game[] public history;

    /**
     * @dev Leaderboard (top 10 games)
     */
    Game[10] public leaderboard;

    /**
     * @dev Game added to history
     * @param gameIndex index of the game in history
     * @param game struct values
     */
    event GameSaved(uint256 gameIndex, Game game);

    /**
     * @dev Save a Game
     * @param roomName name of game room
     * @param playerName name of winning player
     * @param score winning score
     */
    function save(string memory roomName, string memory playerName, uint256 score) public {
        Game memory newGame = Game(roomName, playerName, score);

        history.push(newGame);

        insertSortLeaderboard(newGame);

        emit GameSaved(history.length - 1, newGame);
    }

    /**
     * @dev Get entire Leaderboard
     * @return leaders
     */
    function top10() public view returns (Game[10] memory){
        return leaderboard;
    }

    /**
     * @dev Get History length
     * @return length
     */
    function length() public view returns (uint256){
        return history.length;
    }

    /**
     * @dev Sort the Leaderboard
     * @param newGame new game to insert in order by score
     */
    function insertSortLeaderboard(Game memory newGame) internal {
        uint leaderboardLength = leaderboard.length;
        uint i = 0;

        for(i = 0; i < leaderboardLength; i++) {
            if(leaderboard[i].winningScore < newGame.winningScore) {
                break;
            }
        }

        for(uint j = leaderboardLength - 1; j > i; j--) {
            leaderboard[j] = leaderboard[j - 1];
        }

        leaderboard[i] = newGame;
    }
}