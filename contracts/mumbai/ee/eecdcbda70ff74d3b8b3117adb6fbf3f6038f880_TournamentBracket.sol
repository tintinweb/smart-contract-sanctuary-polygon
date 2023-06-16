/**
 *Submitted for verification at polygonscan.com on 2023-06-15
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract TournamentBracket {
    struct Match {
        uint256 matchId;
        uint256 round;
        string teamA;
        string teamB;
        uint256 teamAScore;
        uint256 teamBScore;
        bool isFinished;
    }

    mapping(uint256 => Match) public matches;
    uint256 public currentMatchId;
    uint256 public currentRound;
    uint256 public totalRounds;

    function initialize(uint256 _totalRounds) external {
        require(_totalRounds > 0, "Total rounds must be greater than zero");
        totalRounds = _totalRounds;
        currentRound = 1;
    }
   
    function reset() external {
        delete currentMatchId;
        delete currentRound;
        delete totalRounds;
    }

    function createMatch(string memory _teamA, string memory _teamB) external {
        require(currentRound <= totalRounds, "Tournament has ended");
        require(currentRound != 0, "Tournament hasn't started");
        require(bytes(_teamA).length > 0 && bytes(_teamB).length > 0, "Team names must not be empty");

        currentMatchId++;

        Match storage newMatch = matches[currentMatchId];
        newMatch.matchId = currentMatchId;
        newMatch.teamA = _teamA;
        newMatch.teamB = _teamB;

        if (currentMatchId > (2**(totalRounds - currentRound))) {
            currentRound++;
        }
        newMatch.round = currentRound;
    }

    function updateMatchResult(uint256 _matchId, uint256 _teamAScore, uint256 _teamBScore) external {
        require(_matchId <= currentMatchId, "Invalid match ID");
        require(matches[_matchId].isFinished == false, "Match result has already been updated");

        Match storage matchToUpdate = matches[_matchId];
        matchToUpdate.teamAScore = _teamAScore;
        matchToUpdate.teamBScore = _teamBScore;
        matchToUpdate.isFinished = true;
    }

    function getBracketState() external view returns (Match[] memory) {
        Match[] memory bracketState = new Match[](currentMatchId);
        for (uint256 i = 1; i <= currentMatchId; i++) {
            bracketState[i-1] = matches[i];
        }
        return bracketState;
    }
}