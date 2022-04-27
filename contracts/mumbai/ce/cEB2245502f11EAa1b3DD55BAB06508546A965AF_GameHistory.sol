/**
 *Submitted for verification at polygonscan.com on 2022-04-27
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
        uint256 index;
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
     * @param roomName index of the game in history
     * @param game struct values
     */
    event GameSaved(string indexed roomName, Game game);

    /**
     * @dev Save a Game
     * @param roomName name of game room
     * @param playerName name of winning player
     * @param score winning score
     */
    function save(string memory roomName, string memory playerName, uint256 score) public {
        Game memory newGame = Game(roomName, playerName, score, history.length);

        history.push(newGame);

        insertSortLeaderboard(newGame);

        emit GameSaved(newGame.roomName, newGame);
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
        if(newGame.winningScore <= leaderboard[9].winningScore) return;

        uint256 len = leaderboard.length;
        
        // Set insertAt to the slot the new game should be inserted at
        uint256 insertAt = 0;
        for(insertAt = 0; insertAt < len; insertAt++) {
            if(leaderboard[insertAt].winningScore < newGame.winningScore) break;
        }

        // Shift items right by one, starting from the end of the array until the slot insertAt
        for(uint256 shift = len - 1; shift > insertAt; shift--) {
            leaderboard[shift] = leaderboard[shift - 1];
        }

        // Insert the new game at slot insertAt
        leaderboard[insertAt] = newGame;
    }
}