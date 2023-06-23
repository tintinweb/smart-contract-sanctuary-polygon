/**
 *Submitted for verification at polygonscan.com on 2023-06-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract TournamentBracket {
    struct Contest {
        string player1;
        string player2;
        string winner;
        bool isFinished;
    }

    uint256 public tournamentId;
    mapping(uint256 => Contest[]) internal brackets;

    event ContestResult(uint256 tournamentId, uint256 contestIndex, string winner);

    function createNewTournament(string[] memory _participants) external {
        uint256 newTournamentId = tournamentId + 1;

        uint256 numOfContest = _participants.length / 2;

        for (uint256 i = 0; i < numOfContest; i++) {
            Contest storage newContest = brackets[newTournamentId][i];
            newContest.player1 = _participants[i * 2];
            newContest.player2 = _participants[i * 2 + 1];
        }

        tournamentId++;

    }

    function getBracket(uint256 _tournamentId) external view returns (Contest[] memory) {
        return brackets[_tournamentId];
    }

    function submitContestResult(uint256 _tournamentId, uint256 _contestIndex, string calldata _winner) external {
        Contest storage contest = brackets[_tournamentId][_contestIndex];
        require(!contest.isFinished, "Contest already finished");

        contest.winner = _winner;
        contest.isFinished = true;

        emit ContestResult(_tournamentId, _contestIndex, _winner);
    }
}