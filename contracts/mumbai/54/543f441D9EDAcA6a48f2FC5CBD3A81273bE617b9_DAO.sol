/**
 *Submitted for verification at polygonscan.com on 2022-04-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract DAO {
    struct Proposal {
        uint256 proposalID;
        string proposalName;
        string proposalDesc;
        address proposer;
        uint256 proposalAmount;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 voteDeadline;
        bool isValid;
        bool isPassed;
        bool isPaid;
    }

    event ThanksMessage(string message);

    uint256 counter = 1;
    mapping(address => Proposal[]) public myProposals;
    mapping(uint256 => Proposal) public allProposalsIndexed;
    Proposal[] public allProposals;
    mapping(address => uint256) public donationAmount;

    fallback() external payable {
        donationAmount[msg.sender] += msg.value;
        emit ThanksMessage("Thank you for donating!");
    }

    receive() external payable{
        donationAmount[msg.sender] += msg.value;
        emit ThanksMessage("Thank you for donating!");
    }

    modifier hasExpired(uint256 _id) {
        require(allProposalsIndexed[_id].isValid, "Proposal Voting Expired");
        _;
        if (allProposalsIndexed[_id].voteDeadline - 1 < block.timestamp) {
            allProposalsIndexed[_id].isValid = false;
            countVotes(_id);
        }
    }

    function makeProposal(
        string calldata _proposalName,
        string calldata _proposalDesc,
        uint amount
    ) public payable returns (bool) {
        require(msg.value >= 1 * 10**15, "Minimum contribution is 0.001 ETH");
        Proposal memory newProposal;

        newProposal.proposalID = counter;
        newProposal.proposalName = _proposalName;
        newProposal.proposalDesc = _proposalDesc;
        newProposal.proposalAmount = amount;
        newProposal.proposer = tx.origin;
        newProposal.forVotes = 0;
        newProposal.againstVotes = 0;
        newProposal.voteDeadline = block.timestamp + 432000;
        newProposal.isValid = true;
        newProposal.isPassed = false;
        newProposal.isPaid = false;

        allProposals.push(newProposal);
        myProposals[tx.origin].push(newProposal);
        allProposalsIndexed[counter] = newProposal;
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
        return (allProposalsIndexed[_id]);
    }

    function countVotes(uint256 _id) public {
        require(
            address(this).balance > allProposalsIndexed[_id].proposalAmount,
            "Not enough balance to payout"
        );
        require(allProposalsIndexed[_id].isPassed, "Already Passed");
        require(allProposalsIndexed[_id].isPaid, "Already Paid or Proposal lost");
        require(allProposalsIndexed[_id].isValid, "Not Expired Yet");
        if (
            allProposalsIndexed[_id].forVotes >
            allProposalsIndexed[_id].againstVotes
        ) {
            allProposalsIndexed[_id].isPassed = true;
            allProposalsIndexed[_id].isPaid = true;
            allProposalsIndexed[_id].isValid = false;
            payable(allProposalsIndexed[_id].proposer).transfer(
                (allProposalsIndexed[_id].proposalAmount * 95) / 100
            );
        } else {
            allProposalsIndexed[_id].isPassed = false;
            allProposalsIndexed[_id].isPaid = true;
            allProposalsIndexed[_id].isValid = false;
        }
    }

    function voteFor(uint256 _id) public hasExpired(_id) returns (bool) {
        require(donationAmount[msg.sender]>=0, "Please donate before voting!");
        allProposalsIndexed[_id].forVotes += 1;
        return(true);
    }
    function voteAgainst(uint256 _id) public hasExpired(_id) returns (bool) {
        require(donationAmount[msg.sender]>=0, "Please donate before voting!");
        allProposalsIndexed[_id].againstVotes +=1;
        return(true);
    }
}