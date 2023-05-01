/**
 *Submitted for verification at polygonscan.com on 2023-04-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Voting {

    // Proposalの構造
    struct Proposal {
        uint id;
        string title;
        address[] voters;
    }

    // ProposalのIDの管理
    uint private currentProposalId = 1;
    // IDからProposalを取得するmapping
    mapping(uint => Proposal) public proposals;
    // 投票済みのWalletAddressを管理
    mapping(address => bool) public hasVoted;

    // Proposalの追加
    function createProposal(string memory _title) public {
        address[] memory emptyVotersArray;
        proposals[currentProposalId] = Proposal(currentProposalId, _title, emptyVotersArray);
        currentProposalId++;
    }

    // Voteする
    function vote(uint _proposalId) public {
        // 1 WalletAddresにつき 1 票まで
        require(!hasVoted[msg.sender], "Already voted");
        
        // Proposalが存在しているか確認
        require(proposals[_proposalId].id != 0, "Proposal not found");

        // ProposalにVoteする
        proposals[_proposalId].voters.push(msg.sender);
        hasVoted[msg.sender] = true;
    }

    // ProposalIDのProposalを取得
    function getProposal(uint _proposalId) public view returns (Proposal memory) {
        require(proposals[_proposalId].id != 0, "Proposal not found");
        return proposals[_proposalId];
    }

    // ProposalIDの投票者一覧の取得
    function getVotersForProposal(uint _proposalId) public view returns (address[] memory) {
        require(proposals[_proposalId].id != 0, "Proposal not found");
        return proposals[_proposalId].voters;
    }

    // Proposalの一覧を取得
    function getAllProposals() public view returns (Proposal[] memory) {
        Proposal[] memory allProposals = new Proposal[](currentProposalId - 1);
        for (uint i = 1; i < currentProposalId; i++){
            allProposals[i - 1] = proposals[i];
        }
        return allProposals;
    }

    // 一番投票者が多いProposalを取得
    function getMostVotedProposal() public view returns (Proposal memory) {
        uint maxVoteCount = 0;
        uint maxVotedProposalId;

        for (uint i = 0; i < currentProposalId; i++) {
            if (proposals[i].voters.length > maxVoteCount) {
                maxVoteCount = proposals[i].voters.length;
                maxVotedProposalId = i;
            }
        }

        return proposals[maxVotedProposalId];
    }
}