/**
 *Submitted for verification at polygonscan.com on 2023-03-02
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract ISLAMIquiz_V1 {


    address public admin = 0xB495EfB6d04400342919d0D2c0E6C120Ad814500;

    struct Player {
        uint256 score;
        bool exists;
        uint256 index;
    }

    mapping(address => Player) public players;

    address[] public topPlayers;
    uint256 public maxTopPlayers = 10;

    event ScoreUpdated(address indexed player, uint256 score);


    function updateScore(address _player, uint256 score) public {
        require(msg.sender == admin, "Not authorized!");
        require(score >= 0, "Score must be non-negative.");

        Player storage player = players[_player];

        if (!player.exists) {
            player.exists = true;
            player.index = topPlayers.length;
            topPlayers.push(_player);
        }

        player.score += score;
        players[_player].score += score;
        emit ScoreUpdated(_player, score);

        if (topPlayers.length > maxTopPlayers) {
            removeLowestScore();
        }
    }

    function setMaxTopPlayers(uint256 _num) external{
        require(msg.sender == admin, "Not authorized!");
        require(_num > 0,"Zero!");
        maxTopPlayers = _num;
    }
    function removeLowestScore() internal {
        uint256 lowestScore = players[topPlayers[0]].score;
        uint256 lowestIndex = 0;

        for (uint256 i = 1; i < topPlayers.length; i++) {
            if (players[topPlayers[i]].score < lowestScore) {
                lowestScore = players[topPlayers[i]].score;
                lowestIndex = i;
            }
        }

        address lowestPlayer = topPlayers[lowestIndex];

        // Move the last player in the list to the lowest player's position
        address lastPlayer = topPlayers[topPlayers.length - 1];
        players[lastPlayer].index = lowestIndex;
        topPlayers[lowestIndex] = lastPlayer;

        // Remove the lowest player from the list
        topPlayers.pop();
        delete players[lowestPlayer];
    }

    function getTopPlayers() public view returns (address[] memory, uint256[] memory) {
    uint256 numPlayers = topPlayers.length;

    address[] memory playerList = new address[](numPlayers);
    uint256[] memory scoreList = new uint256[](numPlayers);

    for (uint256 i = 0; i < numPlayers; i++) {
        address playerAddress = topPlayers[i];
        playerList[i] = playerAddress;
        scoreList[i] = players[playerAddress].score;
    }

    return (playerList, scoreList);
}

}


               /*********************************************************
                  Proudly Developed by MetaIdentity ltd. Copyright 2023
               **********************************************************/