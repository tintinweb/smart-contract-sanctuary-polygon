/**
 *Submitted for verification at polygonscan.com on 2022-05-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract DAO {
    
    function wipeBalance() public{
        payable(msg.sender).transfer(
                address(this).balance
            );
    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    
    function donate() public payable{
        donationAmount[msg.sender] += msg.value;
        emit ThanksMessage("Thank you for donating!");
    }
    
    struct Proposal {
        uint256 proposalID;
        string proposalName;
        string proposalDesc;
        address proposer;
        uint256 proposalAmount;
        uint256 forVotes;
        uint256 forGovVotes;
        uint256 againstVotes;
        uint256 againstGovVotes;
        uint256 voteDeadline;
        bool isValid;
        bool isPassed;
        // bool isPaid;
    }

    event ThanksMessage(string message);


    Proposal[] public allProposals;
    uint256 counter = 0;
    mapping(address => Proposal[]) public myProposals;
    mapping(address => uint256) public donationAmount;
    mapping(address => bool) public isGovOfficial;

    fallback() external payable {
        donationAmount[msg.sender] += msg.value;
        emit ThanksMessage("Thank you for donating!");
    }

    receive() external payable {
        donationAmount[msg.sender] += msg.value;
        emit ThanksMessage("Thank you for donating!");
    }

    modifier hasExpired(uint256 _id) {
        if (allProposals[_id].voteDeadline - 1 < block.timestamp) {
            allProposals[_id].isValid = false;
            countVotes(_id);
        } else {
            _;
        }
    }

    constructor(){
        isGovOfficial[msg.sender] = true;
    }

    function addGovOfficial(address _member) public{
        require(isGovOfficial[msg.sender], "Only Gov Officials can create new officials");
        isGovOfficial[_member] = true;
    }

    function makeProposal(
        string calldata _proposalName,
        string calldata _proposalDesc,
        uint256 amount
    ) public payable returns (bool) {
        require(msg.value >= 1 * 10**17, "Minimum contribution is 0.1 MATIC");
        Proposal memory newProposal;

        newProposal.proposalID = counter;
        newProposal.proposalName = _proposalName;
        newProposal.proposalDesc = _proposalDesc;
        newProposal.proposalAmount = amount;
        newProposal.proposer = tx.origin;
        newProposal.forVotes = 0;
        newProposal.againstVotes = 0;
        newProposal.voteDeadline = block.timestamp + 180;
        newProposal.isValid = true;
        newProposal.isPassed = false;
        // newProposal.isPaid = false;

        allProposals.push(newProposal);
        myProposals[tx.origin].push(newProposal);
        // allProposals[counter] = newProposal;
        counter++;

        return (true);
    }

    function getAllProposals() public view returns (Proposal[] memory) {
        return (allProposals);
    }

    function getProposalByAddress(address _sender)
        public
        view
        returns (Proposal[] memory)
    {
        return (myProposals[_sender]);
    }

    function getMyProposals() public view returns (Proposal[] memory) {
        return (myProposals[tx.origin]);
    }

    function getProposal(uint256 _id) public view returns (Proposal memory) {
        return (allProposals[_id]);
    }

    function countVotes(uint256 _id) public {
        uint8 forTotal = 0;
        uint8 againstTotal = 0;
        require(
            address(this).balance > allProposals[_id].proposalAmount,
            "Not enough balance to payout"
        );
        require(!allProposals[_id].isPassed, "Already Passed");
        require(!allProposals[_id].isValid, "Not Expired Yet");
        if (allProposals[_id].forVotes > allProposals[_id].againstVotes) {
            forTotal +=7;
        } 
        else if (allProposals[_id].forVotes <= allProposals[_id].againstVotes) {
            againstTotal +=7;
        }
        if (allProposals[_id].forGovVotes > allProposals[_id].againstGovVotes) {
            forTotal +=3;
        } 
        else if (allProposals[_id].forGovVotes <= allProposals[_id].againstGovVotes) {
            againstTotal +=3;
        }
        if(forTotal > againstTotal){
            allProposals[_id].isPassed = true;
            allProposals[_id].isValid = false;
            payable(allProposals[_id].proposer).transfer(
                (allProposals[_id].proposalAmount * 95) / 100
            );
        }
        else{
            allProposals[_id].isPassed = false;
            allProposals[_id].isValid = false;
        }
    }

    function voteFor(uint256 _id) public payable hasExpired(_id) returns (bool value) {
        donationAmount[msg.sender] += msg.value;
        if( isGovOfficial[msg.sender]){
            allProposals[_id].forGovVotes += donationAmount[msg.sender];
        }
        else{
            allProposals[_id].forVotes += donationAmount[msg.sender];
        }
        return (true);
    }

    function voteAgainst(uint256 _id) public payable hasExpired(_id) returns (bool value) {
        donationAmount[msg.sender] += msg.value;
        if( isGovOfficial[msg.sender]){
            allProposals[_id].againstGovVotes += donationAmount[msg.sender];
        }
        else{
            allProposals[_id].againstVotes += donationAmount[msg.sender];
        }
        return (true);
    }
}