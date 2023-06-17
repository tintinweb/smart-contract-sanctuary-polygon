// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Election {
    struct candidate {
        uint256 id;
        string name;
        uint voteCount;
    }

    mapping(uint256 => candidate) public candidates;
    uint256 public candidatesCount;
    mapping(address => bool) public voters;

    constructor() {
        addCandidate("Federal");
        addCandidate("Republican");
    }

    function addCandidate(string memory _name) private {
        candidatesCount++;
        candidates[candidatesCount] = candidate(candidatesCount, _name, 0);
    }

    function vote(uint256 _candidateId) public {
        require(!voters[msg.sender], "You can only vote once");
        require(_candidateId > 0 && _candidateId <= candidatesCount);
        candidates[_candidateId].voteCount++;
        voters[msg.sender] = true;
    }

    function getCandidates() public view returns (candidate[] memory) {
        candidate[] memory allCandidates = new candidate[](candidatesCount);

        for (uint256 i = 1; i <= candidatesCount; i++) {
            candidate storage c = candidates[i];
            allCandidates[i - 1] = c;
        }

        return allCandidates;
    }
}