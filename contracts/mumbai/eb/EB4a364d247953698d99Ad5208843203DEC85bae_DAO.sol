// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract DAO {

    struct Proposal {
        string description;
        uint voteCount;
        bool executed;
    }

    struct Member {
        address memberAddress;
        uint memberSince;
        uint tokenBalance;
    }

    address[] public members;
    mapping(address => Member) public memberInfo;
    mapping(address => mapping(uint => bool)) public votes;
    Proposal[] public proposals;

    uint public totalSupply;
    mapping(address => uint) public balances;

    event ProposalCreated(uint indexed proposalId, string description);
    event VoteCast(address indexed voter, uint indexed proposalId, uint tokenAmount);

    function addMember(address _member) public {
        require(memberInfo[_member].memberAddress == address(0), "Member already exists");
        memberInfo[_member] = Member({
            memberAddress: _member,
            memberSince: block.timestamp,
            tokenBalance: 100
        });
        members.push(_member);
        balances[_member] = 100;
        totalSupply += 100;
    }

    function removeMember(address _member) public {
        require(memberInfo[_member].memberAddress != address(0), "Member does not exist");
        memberInfo[_member] = Member({
            memberAddress: address(0),
            memberSince: 0,
            tokenBalance: 0
        });
        for (uint i = 0; i < members.length; i++) {
            if (members[i] == _member) {
                members[i] = members[members.length - 1];
                members.pop();
                break;
            }
        }
        balances[_member] = 0;
        totalSupply -= 100;
    }

    function createProposal(string memory _description) public {
        proposals.push(Proposal({
            description: _description,
            voteCount: 0,
            executed: false
        }));
        emit ProposalCreated(proposals.length - 1, _description);
    }

    function vote(uint _proposalId, uint _tokenAmount) public {
        require(memberInfo[msg.sender].memberAddress != address(0), "Only members can vote");
        require(balances[msg.sender] >= _tokenAmount, "Not enough tokens to vote");
        require(votes[msg.sender][_proposalId] == false, "You have already voted for this proposal");
        votes[msg.sender][_proposalId] = true;
        memberInfo[msg.sender].tokenBalance -= _tokenAmount;
        proposals[_proposalId].voteCount += 1;
        emit VoteCast(msg.sender, _proposalId, _tokenAmount);
    }

    function executeProposal(uint _proposalId) public {
        require(proposals[_proposalId].executed == false, "Proposal has already been executed");
        require(((proposals[_proposalId].voteCount / (totalSupply/100))*100) > 50, "Proposal has not been approved by majority vote");
        proposals[_proposalId].executed = true;
        // execute proposal here
    }

}