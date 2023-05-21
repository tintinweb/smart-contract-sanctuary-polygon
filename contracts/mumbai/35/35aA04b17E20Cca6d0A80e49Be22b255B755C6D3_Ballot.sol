// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Ballot {
    struct Voter {
        uint256 weight; // weight is accumulated by delegation
        bool voted; // if true, that person already voted
        address delegate; // person delegated to
        uint256 vote; // index of the voted proposal
    }

    // This is a type for a single proposal.
    struct Proposal {
        string name; // short name (up to 32 bytes)
        uint256 voteCount; // number of accumulated votes
    }

    address public chairperson;

    struct Party {
        string name;
        Proposal[] proposals;
        mapping(address => Voter) voters;
    }

    Party[] public party;

    uint256 public partyCount;

    enum SESSION {
        PRIMARY_ELECTION,
        GENERAL_ELECTION
    }

    SESSION private session;

    Proposal[] public winningSession;
    mapping(address => Voter) votersForWinningSession;

    uint256 public lockContract;

    /// Create a new ballot to choose one of `proposalNames`.
    constructor() payable {
        chairperson = msg.sender;
        partyCount = 0;
        session = SESSION.PRIMARY_ELECTION;
        lockContract = block.timestamp + (10 days);
    }

    function addToParty(
        string memory partyName,
        string[] memory proposalNames
    ) public payable onlyChairperson {
        require(
            block.timestamp <= lockContract,
            "Time up, can not add to party"
        );
        require(
            session == SESSION.PRIMARY_ELECTION,
            "Can not add party in COUNTRY_VOTE session"
        );
        Party storage newParty = party.push();
        newParty.name = partyName;
        for (uint256 i = 0; i < proposalNames.length; i++) {
            newParty.proposals.push(
                Proposal({name: proposalNames[i], voteCount: 0})
            );
        }
        partyCount++;
    }

    // Give `voter` the right to vote on this party.
    // May only be called by `chairperson`.
    function giveRightToVote(uint256 partyId, address voter) external {
        if (session == SESSION.PRIMARY_ELECTION) {
            require(
                msg.sender == chairperson,
                "Only chairperson can give right to vote."
            );
            require(
                !party[partyId].voters[voter].voted,
                "The voter already voted."
            );
            require(party[partyId].voters[voter].weight == 0);
            party[partyId].voters[voter].weight = 1;
        } else {
            require(
                msg.sender == chairperson,
                "Only chairperson can give right to vote."
            );
            require(
                !votersForWinningSession[voter].voted,
                "The voter already voted."
            );
            require(votersForWinningSession[voter].weight == 0);
            votersForWinningSession[voter].weight = 1;
        }
    }

    /// Delegate your vote to the voter `to`.
    function delegate(uint256 partyId, address to) external {
        if (session == SESSION.PRIMARY_ELECTION) {
            // assigns reference
            Voter storage sender = party[partyId].voters[msg.sender];
            require(sender.weight != 0, "You have no right to vote");
            require(!sender.voted, "You already voted.");

            require(to != msg.sender, "Self-delegation is disallowed.");

            while (party[partyId].voters[to].delegate != address(0)) {
                to = party[partyId].voters[to].delegate;

                // We found a loop in the delegation, not allowed.
                require(to != msg.sender, "Found loop in delegation.");
            }

            Voter storage delegate_ = party[partyId].voters[to];

            // Voters cannot delegate to accounts that cannot vote.
            require(delegate_.weight >= 1);

            // Since `sender` is a reference, this
            // modifies `voters[msg.sender]`.
            sender.voted = true;
            sender.delegate = to;

            if (delegate_.voted) {
                // If the delegate already voted,
                // directly add to the number of votes
                party[partyId].proposals[delegate_.vote].voteCount += sender
                    .weight;
            } else {
                // If the delegate did not vote yet,
                // add to her weight.
                delegate_.weight += sender.weight;
            }
        } else {
            Voter storage sender = votersForWinningSession[msg.sender];
            require(sender.weight != 0, "You have no right to vote");
            require(!sender.voted, "You already voted.");

            require(to != msg.sender, "Self-delegation is disallowed.");

            while (votersForWinningSession[to].delegate != address(0)) {
                to = votersForWinningSession[to].delegate;

                require(to != msg.sender, "Found loop in delegation.");
            }

            Voter storage delegate_ = votersForWinningSession[to];

            require(delegate_.weight >= 1);

            sender.voted = true;
            sender.delegate = to;

            if (delegate_.voted) {
                winningSession[delegate_.vote].voteCount += sender.weight;
            } else {
                delegate_.weight += sender.weight;
            }
        }
    }

    /// Give your vote (including votes delegated to you)
    /// to proposal `proposals[proposal].name`.
    function vote(uint256 partyId, uint256 proposal) external {
        if (session == SESSION.PRIMARY_ELECTION) {
            Voter storage sender = party[partyId].voters[msg.sender];
            require(sender.weight != 0, "Has no right to vote");
            require(!sender.voted, "Already voted.");
            sender.voted = true;
            sender.vote = proposal;

            // If `proposal` is out of the range of the array,
            // this will throw automatically and revert all
            // changes.
            party[partyId].proposals[proposal].voteCount += sender.weight;
        } else {
            Voter storage sender = votersForWinningSession[msg.sender];
            require(sender.weight != 0, "Has no right to vote");
            require(!sender.voted, "Already voted.");
            sender.voted = true;
            sender.vote = proposal;

            winningSession[proposal].voteCount += sender.weight;
        }
    }

    /// @dev Computes the winning proposal taking all
    /// previous votes into account.
    function winningProposal(
        uint256 partyId
    ) public view returns (uint256 winningProposal_) {
        uint256 winningVoteCount = 0;
        for (uint256 p = 0; p < party[partyId].proposals.length; p++) {
            if (party[partyId].proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = party[partyId].proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    // // Calls winningProposal() function to get the index
    // // of the winner contained in the proposals array and then
    // // returns the name of the winner
    function winnerPrimary() public {
        require(
            session == SESSION.PRIMARY_ELECTION,
            "Not in primary election progress"
        );
        require(lockContract < block.timestamp, "Voting in progress");
        for (uint256 i = 0; i < party.length; i++) {
            string memory winnerName = party[i]
                .proposals[winningProposal(i)]
                .name;
            winningSession.push(Proposal({name: winnerName, voteCount: 0}));
        }
        session = SESSION.GENERAL_ELECTION;
        // lockContract = block.timestamp + (5 days);
    }

    function winningProposalGeneral()
        public
        view
        returns (uint256 winningProposal_)
    {
        uint256 winningVoteCount = 0;
        for (uint256 p = 0; p < winningSession.length; p++) {
            if (winningSession[p].voteCount > winningVoteCount) {
                winningVoteCount = winningSession[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    function winnerGeneral() external view returns (string memory winnerName_) {
        require(
            session == SESSION.GENERAL_ELECTION,
            "Not in general election progress"
        );
        require(lockContract < block.timestamp, "Voting in progress");
        winnerName_ = winningSession[winningProposalGeneral()].name;
    }

    // function getParties() public view returns (Party[] memory) {
    //     return party;
    // }

    modifier onlyChairperson() {
        require(msg.sender == chairperson, "You are not chairperson");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}