/**
 *Submitted for verification at polygonscan.com on 2023-03-03
*/

pragma solidity ^0.8.0;
//SPDX-License-Identifier: UNLICENSED
contract Tournament {
    
    struct Match {
        uint256 homeTeam;
        uint256 awayTeam;
        bool played;
        uint256 homeTeamScore;
        uint256 awayTeamScore;
    }
    
    struct Player {
        string name;
        bool exists;
    }
    
    mapping(uint256 => Player) public players;
    mapping(uint256 => mapping(uint256 => Match)) public matches;
    uint256 public numPlayers;
    uint256 public numMatches;
    
    function addPlayer(string memory _name) public {
        require(numPlayers < 20, "The maximum number of players has been reached");
        numPlayers++;
        players[numPlayers] = Player(_name, true);
    }
    
    function addMultiplePlayers(string[] memory _names) public {
        require(numPlayers + _names.length <= 20, "The maximum number of players has been reached");
        for (uint256 i = 0; i < _names.length; i++) {
            numPlayers++;
            players[numPlayers] = Player(_names[i], true);
        }
    }
    
    function generateSchedule() public {
        require(numPlayers == 20, "The tournament needs exactly 20 players");
        for (uint256 i = 1; i <= numPlayers - 1; i++) {
            for (uint256 j = i + 1; j <= numPlayers; j++) {
                numMatches++;
                matches[i][j] = Match(i, j, false, 0, 0);
                numMatches++;
                matches[j][i] = Match(j, i, false, 0, 0);
            }
        }
    }
    
    function playMatch(uint256 _homeTeam, uint256 _awayTeam, uint256 _homeTeamScore, uint256 _awayTeamScore) public {
        require(players[_homeTeam].exists && players[_awayTeam].exists, "Both teams must exist");
        require(matches[_homeTeam][_awayTeam].played == false, "Match has already been played");
        matches[_homeTeam][_awayTeam].played = true;
        matches[_homeTeam][_awayTeam].homeTeamScore = _homeTeamScore;
        matches[_homeTeam][_awayTeam].awayTeamScore = _awayTeamScore;
        matches[_awayTeam][_homeTeam].played = true;
        matches[_awayTeam][_homeTeam].homeTeamScore = _awayTeamScore;
        matches[_awayTeam][_homeTeam].awayTeamScore = _homeTeamScore;
    }
    
}