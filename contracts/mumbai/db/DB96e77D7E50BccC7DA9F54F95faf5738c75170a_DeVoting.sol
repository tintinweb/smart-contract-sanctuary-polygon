/**
 *Submitted for verification at polygonscan.com on 2022-09-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface VOTING {
    function Add_Candidates(string[] memory Names, uint256[] memory id)
        external;

    function Click_To_Vote() external;

    function vote(uint256 candidate) external;

    function show_winner() external view returns (string memory winner_);

    function SHOWTIME()
        external
        view
        returns (
            uint256 Add_candidates,
            uint256 Show_winner,
            uint256 Ending_time
        );
}

contract DeVoting is VOTING {
    // struct for candidates' information
    struct Candidate {
        string name; // the candidate has a name
        uint256 ID; // the candidate has also an ID
        uint256 voteCounter; // number of overall votes
    }

    // struct for voter
    struct People {
        uint256 weight; // It basically defines how many votes you can give
        bool voted; // If true, that person has already voted
        uint256 vote_index; // index of the voted
    }

    struct Times {
        uint256 Add_Candidates_Time; // you can set a deadline for adding candidates
        uint256 Show_Winner_Time; // you can set a time for showing the winner
        uint256 Ending_Time; // the time that voting comes to the end
    }

    mapping(address => People) private voters; //This stores a `People` struct for each address.
    Candidate[] public ID;
    Times TIMES;
    address public Owner;
    uint256 starttime;

    // The owner(who deploys the contract) can set the times in day
    constructor(
        uint256 ACT,
        uint256 SWT,
        uint256 ET
    ) {
        Owner = msg.sender;
        starttime = block.timestamp;
        TIMES.Add_Candidates_Time = ACT;
        TIMES.Show_Winner_Time = SWT;
        TIMES.Ending_Time = ET;
    }

    // Just the Owner can add candidates with Names & ID.
    // Adding candidates' gonna be stoped at the time that has been set
    function Add_Candidates(string[] memory Names, uint256[] memory id) public {
        require(
            starttime + TIMES.Add_Candidates_Time * 86400 > block.timestamp,
            "time is out"
        );
        require(msg.sender == Owner, "Only Owner can add candidates");
        voters[Owner].weight = 1;

        for (uint256 i = 0; i < Names.length; i++) {
            ID.push(Candidate({name: Names[i], voteCounter: 0, ID: id[i]}));
        }
    }

    // Call this function to vote
    function Click_To_Vote() public {
        require(
            starttime + TIMES.Ending_Time * 86400 > block.timestamp,
            "time is out"
        );
        require(!voters[msg.sender].voted, "The voter has already voted.");
        require(voters[msg.sender].weight == 0);
        voters[msg.sender].weight = 1;
    }

    // people (voters) can vote the candidates(with their indexes)
    function vote(uint256 candidate) public {
        require(
            starttime + TIMES.Ending_Time * 86400 > block.timestamp,
            "time is out"
        );
        People storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote_index = candidate;
        ID[candidate].voteCounter += sender.weight;
    }

    // It will compute a candidate' index with the highest votes.
    function Winner_Votes() private view returns (uint256 Overall_) {
        uint256 winningVoteCount = 0;
        for (uint256 j = 0; j < ID.length; j++) {
            if (ID[j].voteCounter > winningVoteCount) {
                winningVoteCount = ID[j].voteCounter;
                Overall_ = j;
            }
        }
    }

    // The winner's gonna be revealed at the time the owner set
    function show_winner() public view returns (string memory winner_) {
        require(
            starttime + TIMES.Show_Winner_Time * 86400 < block.timestamp,
            "Not yet"
        );
        require(msg.sender == Owner, "Only Owner can show the winner");
        winner_ = ID[Winner_Votes()].name;
    }

    // It shows the remaining time in hour
    function SHOWTIME()
        public
        view
        returns (
            uint256 Add_candidates,
            uint256 Show_winner,
            uint256 Ending_time
        )
    {
        return (
            ((starttime + (TIMES.Add_Candidates_Time * 86400)) -
                block.timestamp) / 3600,
            ((starttime + (TIMES.Show_Winner_Time * 86400)) - block.timestamp) /
                3600,
            ((starttime + (TIMES.Ending_Time * 86400)) - block.timestamp) / 3600
        );
    }
}