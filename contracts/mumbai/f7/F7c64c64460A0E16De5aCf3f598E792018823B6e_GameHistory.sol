/**
 *Submitted for verification at polygonscan.com on 2022-04-21
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
        uint32 winningScore;
    }

    /**
     * @dev Game History
     */
    Game[] history;

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
    function save(string memory roomName, string memory playerName, uint32 score) public {
        Game memory newGame = Game(roomName, playerName, score);

        history.push(newGame);

        emit GameSaved(history.length - 1, newGame);
    }

    /**
     * @dev Return a Game by index
     * @param gameIndex index of the desired Game
     * @return values of Game
     */
    function getById(uint256 gameIndex) public view returns (Game memory){
        return history[gameIndex];
    }
}