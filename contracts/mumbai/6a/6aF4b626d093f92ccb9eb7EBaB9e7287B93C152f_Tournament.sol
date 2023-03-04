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
    function viewCalendar() public view returns (string memory) {
    string memory output = "";
    for (uint256 i = 1; i <= numPlayers - 1; i++) {
        for (uint256 j = i + 1; j <= numPlayers; j++) {
            Match memory matchData = matches[i][j];
            string memory homeTeamName = players[matchData.homeTeam].name;
            string memory awayTeamName = players[matchData.awayTeam].name;
            string memory matchStatus = matchData.played ? " (played)" : " (upcoming)";
            string memory matchScore = matchData.played ? string(abi.encodePacked(" - ", uint2str(matchData.homeTeamScore), ":", uint2str(matchData.awayTeamScore))) : "";
            output = string(abi.encodePacked(output, homeTeamName, " vs ", awayTeamName, matchStatus, matchScore, "\n"));
        }
    }
    return output;
}
function uint2str(uint256 _i) internal pure returns (string memory) {
    if (_i == 0) {
        return "0";
    }
    uint256 j = _i;
    uint256 length;
    while (j != 0) {
        length++;
        j /= 10;
    }
    bytes memory bstr = new bytes(length);
    uint256 k = length;
    while (_i != 0) {
        k = k - 1;
        uint8 temp = uint8(48 + (_i % 10));
        bytes1 b1 = bytes1(temp);
        bstr[k] = b1;
        _i /= 10;
    }
    return string(bstr);
}   
}