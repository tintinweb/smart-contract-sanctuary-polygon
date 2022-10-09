/**
 *Submitted for verification at polygonscan.com on 2022-10-09
*/

// SPDX-License-Identifier: GPL
pragma solidity ^0.8.17;


contract W3HF {

    struct Candidate {
        string twitterId;
        bytes ipfsCid;
        uint votes;
        address wallet;
    }

    event CandidateNominated(bytes32 candidateId, string twitterId, bytes ipfsCid);
    event VotedForCandidate(bytes32 candidateId, address voter);
    event CandidateAccepted(bytes32 candidateId);

    /**
     * Nominee should have more than this value votes
     * to get accepted into the Web3 Hall of Fame.
     */
    uint public acceptanceThreshold;

    /**
     * Mapping of all nominees whether they got
     * accepted or not.
     */
    mapping(bytes32 => Candidate) private candidates;

    /**
     * Mapping to make sure voters can only vote once
     * to the same candidate.
     */
    mapping(bytes32 => mapping(address => bool)) private votes;

    /**
     * Init contract by setting the acceptance threshold.
     */
    constructor(uint _acceptanceThreshold) {
        acceptanceThreshold = _acceptanceThreshold;
    }

    /**
     * Add new nominee to the list.
     * Anyone can do this.
     * Candidates cannot be nominated twice.
     */
    function nominateCandidate(string calldata _twitterId, bytes calldata _ipfsCid) public {
        bytes32 candidateId = keccak256(bytes(_twitterId));
        require(!candidateExists(candidateId), "Candidate exists already.");
        candidates[candidateId].twitterId = _twitterId;
        candidates[candidateId].ipfsCid = _ipfsCid;
        candidates[candidateId].votes = 0;
        emit CandidateNominated(candidateId, _twitterId, _ipfsCid);
    }

    /**
     * Vote for an existing candidate only once.
     */
    function voteForCandidate(bytes32 _candidateId) public {
        require(candidateExists(_candidateId), "Candidate does not exist.");
        require(!votedForCandidate(_candidateId), "Already voted for candidate");
        candidates[_candidateId].votes += 1;
        votes[_candidateId][msg.sender] = true;
        emit VotedForCandidate(_candidateId, msg.sender);
    }

    /**
     * Check if candidate exists or not.
     */
    function candidateExists(bytes32 _candidateId) private view returns (bool) {
        return bytes(candidates[_candidateId].twitterId).length != 0;
    }

    /**
     * Check if elector voted for candidate or not.
     */
    function votedForCandidate(bytes32 _candidateId) private view returns (bool) {
        return votes[_candidateId][msg.sender] == true;
    }
}