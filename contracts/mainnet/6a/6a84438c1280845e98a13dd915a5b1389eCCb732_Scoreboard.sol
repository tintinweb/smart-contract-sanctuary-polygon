//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title Scoreboard Contract
 * Built by the NazaWeb team at https://nazaweb.com
 * @author Daniel Jimenez
 * @notice contract to hold all the scores for the players
 */
contract Scoreboard {
    struct Score {
        string username;
        address player;
        uint256 score;
        uint256 timestamp;
    }

    error Scoreboard__NotUser();
    error Scoreboard__NotSender();

    Score[] public scores;

    /**
     *
     * @param username users ens domain or abbreviated addr
     * @param player users address
     * @param score the score user achieved from playing a game session
     * @param timestamp the time the score was submitted
     */
    event ScoreAdded(
        string indexed username,
        address player,
        uint256 indexed score,
        uint256 indexed timestamp
    );

    constructor() {}

    /**
     *
     * @param _gamer address of the gamer who is submitting the score
     * @param _score the score of the gamer
     * @notice function to add a score to the scoreboard
     */
    function addScore(
        string memory _name,
        address _gamer,
        uint256 _score
    ) public {
        // definitely add signature verification right here that can only be achieved playing the game
        scores.push(Score(_name, _gamer, _score, block.timestamp));
        emit ScoreAdded(_name, _gamer, _score, block.timestamp);
    }

    /**
     * @notice function to get all the scores from the scoreboard
     * @return Score[] memory array of all the scores
     */
    function allScores() public view returns (Score[] memory) {
        return scores;
    }
}