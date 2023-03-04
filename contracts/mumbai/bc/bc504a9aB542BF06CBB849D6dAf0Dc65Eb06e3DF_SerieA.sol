/**
 *Submitted for verification at polygonscan.com on 2023-03-03
*/

pragma solidity ^0.8.0;

//SPDX-License-Identifier: UNLICENSED
contract SerieA {
    address public owner;
    uint public numPlayers;
    mapping(uint => address) public players;
    mapping(address => mapping(address => bool)) public matchesPlayed;
    mapping(uint => mapping(uint => bool)) public schedule;
    
    constructor() {
        owner = msg.sender;
    }
    
    function addPlayer(address player) public {
        require(msg.sender == owner, "Only owner can add players.");
        require(numPlayers < 20, "Maximum number of players reached.");
        
        players[numPlayers] = player;
        numPlayers++;
    }
    
    function generateSchedule() public {
        require(msg.sender == owner, "Only owner can generate schedule.");
        require(numPlayers == 20, "Not enough players to generate schedule.");
        
        uint numMatches = numPlayers * (numPlayers - 1);
        uint numRounds = numPlayers - 1;
        
        for (uint i = 0; i < numRounds; i++) {
            for (uint j = 0; j < numMatches; j++) {
                uint home = (i + j) % (numPlayers - 1);
                uint away = (numPlayers - 1 - j + i) % (numPlayers - 1);
                
                if (j % (numPlayers - 1) == 0) {
                    away = numPlayers - 1;
                }
                
                schedule[home][i] = true;
                schedule[away][i] = true;
            }
        }
    }
    
    function canPlay(address player1, address player2) public view returns(bool) {
        require(matchesPlayed[player1][player2] == false, "Match already played.");
        
        if (matchesPlayed[player2][player1] == false) {
            return true;
        }
        
        for (uint i = 0; i < numPlayers; i++) {
            if (matchesPlayed[player1][players[i]] == false && players[i] != player2) {
                return false;
            }
            
            if (matchesPlayed[player2][players[i]] == false && players[i] != player1) {
                return false;
            }
        }
        
        return true;
    }
    
    function playMatch(address player1, address player2) public {
        require(canPlay(player1, player2), "Players cannot play match.");
        
        matchesPlayed[player1][player2] = true;
        matchesPlayed[player2][player1] = true;
    }
    
    function getPlayers() public view returns(address[] memory) {
        address[] memory playerList = new address[](numPlayers);
        
        for (uint i = 0; i < numPlayers; i++) {
            playerList[i] = players[i];
        }
        
        return playerList;
    }
    
    function getSchedule() public view returns(bool[][] memory) {
        bool[][] memory scheduleList = new bool[][](numPlayers);
        
        for (uint i = 0; i < numPlayers; i++) {
            scheduleList[i] = new bool[](numPlayers);
            
            for (uint j = 0; j < numPlayers - 1; j++) {
                uint opponent = j < i ? j : j + 1;
                scheduleList[i][opponent] = schedule[i][j];
            }
        }
        
        return scheduleList;
    }
    function addPlayers(address[] memory newPlayers) public {
    require(msg.sender == owner, "Only owner can add players.");
    require(numPlayers + newPlayers.length <= 20, "Maximum number of players reached.");

    for (uint i = 0; i < newPlayers.length; i++) {
        players[numPlayers] = newPlayers[i];
        numPlayers++;
    }
}
}