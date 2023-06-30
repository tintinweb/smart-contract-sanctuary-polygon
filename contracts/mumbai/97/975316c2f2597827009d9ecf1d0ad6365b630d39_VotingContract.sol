/**
 *Submitted for verification at polygonscan.com on 2023-06-30
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract VotingContract {

    address private contractAddress;

    constructor() {
        contractAddress = address(this);
    }


    struct Vote {
        uint voteId;
        uint studentId;
        uint politicalPartyId;
    }

    //Vote [] votes_array;
    //mapping(uint => Vote) public votes_map;
    mapping(uint => Vote[]) private votes_registry;



    function registerVote(uint _voteId, uint  _studentId, uint  _politicalPartyId, uint  _electoralProcessId) public {

        Vote memory elector_vote = Vote(_voteId,_studentId, _politicalPartyId);
        
        Vote[] storage tempArray = votes_registry[_electoralProcessId];

        tempArray.push(elector_vote);
        votes_registry[_electoralProcessId] = tempArray;
        
    }


    function getVote(uint  _voteId, uint  _electoralProcessId) public view returns (Vote memory) {
        Vote[] memory tempArray = votes_registry[_electoralProcessId];

        Vote memory elector_vote = Vote(0,0,0);

        for (uint i = 0; i < tempArray.length; i++) {
            if (tempArray[i].voteId == _voteId) 
            {
                elector_vote = tempArray[i];
            }
        }

        return elector_vote;
    }

    function getContractAddres() public view returns(address){
        return contractAddress;
    }

}