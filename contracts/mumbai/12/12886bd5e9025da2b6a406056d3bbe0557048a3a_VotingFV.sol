//Author: Stefan Am Ende
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./VotingStandard.sol";
import "./Utils.sol";


contract VotingFV is VotingStandard{
    struct Candidate{
        string name;
        uint voteCount;
    }

    //7 arrays of candidates for 7 faculties
    Candidate[][7] public candidates;
    //1st dimension -> faculty; 2nd dimension voteIndex; 3rd dimension votes
    uint[][][7] public votes;
    uint[7] internal voteCounts;

    //here the faculties are exceptionally saved from 1 to 7 because 0 is the default value for uint
    mapping (string => uint) private btIdFacultyMappings;

    constructor (string[][] memory candidateNames, uint _start, uint _end, address _owningAddress)
    VotingStandard(_start, _end, _owningAddress){
        require(candidateNames.length == 7, 'You need to pass exactly 7 arrays of candidates.');
        //for each faculty
        for(uint i = 0; i < 7; i++){
            //for each candidate per faculty
            for(uint j = 0; j < candidateNames[i].length; j++)
                candidates[i].push(Candidate(candidateNames[i][j], 0));
        }
    }

    //returns the faculty in the format from 0 to 6
    function getFaculty(string memory btId) public view onlyOwner returns(int faculty){
        return int(btIdFacultyMappings[btId])-1;
    }

    //awaits the faculty in the formal from 0 to 6
    function setFaculty(string memory btId, uint faculty) external onlyOwner{
        require(faculty < 7, 'Invalid faculty ID');
        require(getFaculty(btId) == -1, 'Faculty has already been set');
        btIdFacultyMappings[btId]=faculty+1;
    }

    function vote(uint[] memory candidateIndices, string memory voter) external onlyOwner{
        require(open, 'The election is currently not open');
        require(candidateIndices.length <= 2, 'Exceeded number of votes');
        require(!voters[voter], 'The voter has already voted');
        require(btIdFacultyMappings[voter] != 0, 'Faculty not set');

        uint faculty = btIdFacultyMappings[voter]-1;
        for(uint i = 0; i < candidateIndices.length; i++){
            uint candidateIndex = candidateIndices[i];
            require(candidateIndex < candidates[faculty].length, 'Invalid candidate index');
            candidates[faculty][candidateIndex].voteCount++;
        }
        votes[faculty].push(candidateIndices);
        emit Vote(voteCounts[faculty]++, voter);
        voters[voter] = true;
    }

    function getCandidates(uint faculty) external view returns (Candidate[] memory){
        return candidates[faculty];
    }

    function getCandidateCount(uint faculty) public view returns (uint) {
        return candidates[faculty].length;
    }

    function getVoteByIndex(uint faculty, uint index) public view returns (uint[] memory candidateIndices){
        require(index < voteCounts[faculty], 'Invalid vote index');
        return votes[faculty][index];
    }

    function compareVotes() public override view returns (bool){
        for(uint faculty = 0; faculty < 7; faculty++){
            uint[] memory expectedVoteCounts = new uint[](candidates[faculty].length);
            for(uint i=0; i<candidates[faculty].length; i++){
                expectedVoteCounts[i] = candidates[faculty][i].voteCount;
            }

            for(uint j=0; j<votes[faculty].length; j++){
                for(uint k=0; k<votes[faculty][j].length; k++){
                    uint candidateIndex = votes[faculty][j][k];
                    if(expectedVoteCounts[candidateIndex] > 0){
                        expectedVoteCounts[candidateIndex]--;
                    }
                    else{
                        return false;
                    }
                }
            }

            for(uint l=0; l<expectedVoteCounts.length; l++){
                if(expectedVoteCounts[l] > 0)
                    return false;
            }
        }
        return true;
    }
}