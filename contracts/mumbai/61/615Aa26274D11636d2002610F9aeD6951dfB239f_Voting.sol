/**
 *Submitted for verification at polygonscan.com on 2022-09-28
*/

// Sources flattened with hardhat v2.11.1 https://hardhat.org

// File contracts/Voting.sol

//SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.8.1;

contract Voting {
    mapping(address => bool) public membershipStatus;
    address[] public activeMembers;

    string public mainProposal;
    string[] internal proposalList;
    string[] internal proposalPassed;
    string[] internal proposalRejected;

    address internal owner;
    constructor() {
        owner = msg.sender;
    }
    modifier onlyOwner(){
        require(msg.sender == owner, "you are not owner");
        _;
    }
    function renounceOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    modifier onlyMember(){
        bool status;
        for(uint i=0; i <activeMembers.length; i++) {
            if(activeMembers[i] == msg.sender) {
                status = true;
            }
        }
        require(status == true, "you are not a member");
        _;
    }



    function becomeMember() external payable {
        bool status = false;
        for(uint i=0; i<activeMembers.length; i++) {
            if(activeMembers[i] == msg.sender) {
                status = true;
            }
        }
        require(status == false, "you are already a member");
        require(msg.value >= 1 ether, "pay the membership fee of 1 Matic");
        activeMembers.push(msg.sender);
        membershipStatus[msg.sender] = true;
    }

    function makeProposal(string memory _proposal) external onlyMember {
        proposalList.push(_proposal);
    }

    /*Here the owner is choosing the main proposal from proposal list.
    And there is no reason to keep main proposal inside the proposal list.
    Because it will later go inside passed or rejected list. 
    Thats why I am using for loop in orderly way to remove main proposal.
    We can start for loop from main proposal index and no need to iterate all list
    because in any case we cannot copy the value of last element to another element.
    Thats why i am finishing for loop at "proposalList.length-1
    */
    uint public votingStartTime;
    function chooseMainProposal(uint _index) external onlyOwner {
        require(_index < proposalList.length, "proposal id number is wrong");
        mainProposal = proposalList[_index];
        for(uint i = _index; i < proposalList.length-1; i++) {
            proposalList[i] = proposalList[i+1];
        }
        proposalList.pop();
        votingStartTime = block.timestamp;
    }
    function getAllPro() external view returns(string[] memory) {
        return proposalList;
    }
    function getAllProPassed() external view returns(string[] memory) {
        return proposalPassed;
    }
    function getAllProRejected() external view returns(string[] memory) {
        return proposalRejected;
    }
    function getBalance() external view returns(uint) {
        return (address(this).balance);
    }
    function getDetails() external view returns(address, address) {
        return(owner, address(this));
    }

    /*
    also save members and their proposals in mapping
    also make sure members can make proposal once in a week
    each voting time is limited
    */

    //this struct is to save voting results in resultsMapping after closing the voting.
    struct ResultStruct {
        string proposalName;
        uint yesV;
        uint noV;
        uint totalV;
    }
    ResultStruct record;
    mapping(uint => ResultStruct) internal resultsMapping;

    function getRecordStruct(uint id) external view returns(ResultStruct memory) {
        return resultsMapping[id];
    }

 
    //y: yes votes, n: no votes
    uint internal y;
    uint internal n;
    mapping(address => bool) public votingStatus;
    address[] internal voters;
    function voteYes() external onlyMember {
        require(votingStatus[msg.sender] == false, "you have already voted");
        require(block.timestamp < votingStartTime + 20 minutes, "voting period has ended");
        votingStatus[msg.sender] = true;
        voters.push(msg.sender);
        y++;
    }
    function voteNo() external onlyMember {
        require(votingStatus[msg.sender] == false, "you have already voted");
        require(block.timestamp < votingStartTime + 20 minutes, "voting period has ended");
        votingStatus[msg.sender] = true;
        voters.push(msg.sender);
        n++;
    }
    function getVotingStatus() external view returns(bool) {
        return votingStatus[msg.sender];
    }

    //no need to reset votingStartTime here.
    function closeVoting(uint indexMapping) external onlyOwner {
        uint totalVotes = y + n;
        uint percentage1 = y*100;
        uint percentage2 = percentage1/totalVotes;
        if(percentage2 >= 60) {
            proposalPassed.push(mainProposal);
        } else {
            proposalRejected.push(mainProposal);
        }
        record = ResultStruct(mainProposal, y, n, totalVotes);
        resultsMapping[indexMapping] = record;
    }
    //reset the table for next voting
    function resetTable() external onlyOwner {
        n=0;
        y=0;
        mainProposal = "";
        for(uint i=0; i <voters.length; i++) {
            votingStatus[voters[i]] = false;
        }
        delete voters;
    }

    //leaving membership. First I am searching for member index in activeMembers array.
    //Then I am removing the msg.sender in an orderly way.
    function leaveMembership() external onlyMember {
        uint memberIndex;
        for(uint i=0; i<activeMembers.length; i++) {
            if(activeMembers[i] == msg.sender) {
                memberIndex = i;
                break;
            }
        }
        for(uint i = memberIndex; i < activeMembers.length -1; i++) {
            activeMembers[i] = activeMembers[i+1];
        }
        activeMembers.pop();
        membershipStatus[msg.sender] = false;
    }

    //owner can withdraw all the ether inside the contract
    function withdraw() external onlyOwner {
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "you are not owner");
    }

    //owner can remove a member to prevent exploitation
    function removeMember(address _member) external onlyOwner {
        uint memberIndex;
        for(uint i=0; i<activeMembers.length; i++) {
            if(activeMembers[i] == _member) {
                memberIndex = i;
                break;
            }
        }
        for(uint i = memberIndex; i < activeMembers.length -1; i++) {
            activeMembers[i] = activeMembers[i+1];
        }
        activeMembers.pop();
        membershipStatus[_member] = false;
    }

}