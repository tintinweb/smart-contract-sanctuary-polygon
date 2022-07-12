/**
 *Submitted for verification at polygonscan.com on 2022-07-11
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/cryptography/MerkleProof.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
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
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// File: certificate.sol


pragma solidity ^0.8.0;


contract Certification {
    bytes32 public merkleRootProjectAdmins = 0x49007ef5e6bab1931e03509bb3e1e797f3bf38e7812969c0fc729f585ef08ab0 ;
    bytes32 public merkleRootMentors = 0x9182ff4dcfa8c146be8ad322d6bb3276d06f76fe98e33fd6599a20c985f5addb;
    bytes32 public merkleRoot100Contributors = 0x69955017bc8b332097a405ee105db5a05f694ea780182a102bc43fac962fee59;
    bytes32 public merkleRootContributors = 0x5b4b86ba513b1bb532eaf321bef18829d5e20b011b5cdd1ee44744aa77b2eb89;
    bytes32 public merkleRootCampusAmbassadors = 0x4e35855100e4ffa93ea8a8744580d0d1156bc3ac8e2d9eed9d4898497ca3ad0c; 
    bytes32 public merkleRootOpenSourceAdvocates = 0x1d298d9bd556a9d14b2f01d895e87214bfe04a3ef13fc14b6b9676b8c177e3ec;
    bytes32 public merkleRootOrganizingTeam = 0xccb25a2d346cee45d946454e5c43c08bf40bb37e464675f32a635cfdb7616378;

    // constructor(
    //     bytes32 _merkleRootProjectAdmins,
    //     bytes32 _merkleRootMentors,
    //     bytes32 _merkleRoot100Contributors,
    //     bytes32 _merkleRootContributors,
    //     bytes32 _merkleRootCampusAmbassadors,
    //     bytes32 _merkleRootOpenSourceAdvocates,
    //     bytes32 _merkleRootOrganizingTeam
    //     ) {
    //     merkleRootProjectAdmins = _merkleRootProjectAdmins;
    //     merkleRootMentors = _merkleRootMentors;
    //     merkleRoot100Contributors = _merkleRoot100Contributors;
    //     merkleRootContributors = _merkleRootContributors;
    //     merkleRootCampusAmbassadors = _merkleRootCampusAmbassadors;
    //     merkleRootOpenSourceAdvocates = _merkleRootOpenSourceAdvocates;
    //     merkleRootOrganizingTeam = _merkleRootOrganizingTeam;
    // }

    function verifyPAs(
        bytes32[] calldata merkleProof, 
        string memory participant
        )
        public
        view 
        returns (bool)
    {
        if (
            MerkleProof.verify(
                merkleProof,
                merkleRootProjectAdmins,
                keccak256(bytes(participant))
            )
        ) {
            return true;
        } else {
            return false;
        }
    }

    function verifyMentors(
        bytes32[] calldata merkleProof, 
        string memory participant
        )
        public
        view 
        returns (bool)
    {
        if (
            MerkleProof.verify(
                merkleProof,
                merkleRootMentors,
                keccak256(bytes(participant))
            )
        ) {
            return true;
        } else {
            return false;
        }
    }

    function verifyTop100(
        bytes32[] calldata merkleProof, 
        string memory participant
        )
        public
        view 
        returns (bool)
    {
        if (
            MerkleProof.verify(
                merkleProof,
                merkleRoot100Contributors,
                keccak256(bytes(participant))
            )
        ) {
            return true;
        } else {
            return false;
        }
    }

    function verifyContributors(
        bytes32[] calldata merkleProof, 
        string memory participant
        )
        public
        view 
        returns (bool)
    {
        if (
            MerkleProof.verify(
                merkleProof,
                merkleRootContributors,
                keccak256(bytes(participant))
            )
        ) {
            return true;
        } else {
            return false;
        }
    }

    function verifyCAs(
        bytes32[] calldata merkleProof, 
        string memory participant
        )
        public
        view 
        returns (bool)
    {
        if (
            MerkleProof.verify(
                merkleProof,
                merkleRootCampusAmbassadors,
                keccak256(bytes(participant))
            )
        ) {
            return true;
        } else {
            return false;
        }
    }

    function verifyOpenSourceAdvocates(
        bytes32[] calldata merkleProof, 
        string memory participant
        )
        public
        view 
        returns (bool)
    {
        if (
            MerkleProof.verify(
                merkleProof,
                merkleRootOpenSourceAdvocates,
                keccak256(bytes(participant))
            )
        ) {
            return true;
        } else {
            return false;
        }
    }

    function verifyOrgTeam(
        bytes32[] calldata merkleProof, 
        string memory participant
        )
        public
        view 
        returns (bool)
    {
        if (
            MerkleProof.verify(
                merkleProof,
                merkleRootOrganizingTeam,
                keccak256(bytes(participant))
            )
        ) {
            return true;
        } else {
            return false;
        }
    }
}