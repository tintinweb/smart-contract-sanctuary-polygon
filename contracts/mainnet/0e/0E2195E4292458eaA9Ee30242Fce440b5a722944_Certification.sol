/**
 *Submitted for verification at polygonscan.com on 2022-07-26
*/

// File: @openzeppelin/contracts/utils/cryptography/MerkleProof.sol

// SPDX-License-Identifier: MIT

//  $$$$$$\   $$$$$$\   $$$$$$\             $$$$$$\         $$$$$$\   $$$$$$\  
// $$  __$$\ $$  __$$\ $$  __$$\           $$  __$$\       $$  __$$\ $$  __$$\ 
// $$ /  \__|$$ /  \__|$$ /  \__| $$$$$$\  $$ /  \__|      \__/  $$ |\__/  $$ |
// $$ |$$$$\ \$$$$$$\  \$$$$$$\  $$  __$$\ $$ |             $$$$$$  | $$$$$$  |
// $$ |\_$$ | \____$$\  \____$$\ $$ /  $$ |$$ |            $$  ____/ $$  ____/ 
// $$ |  $$ |$$\   $$ |$$\   $$ |$$ |  $$ |$$ |  $$\       $$ |      $$ |      
// \$$$$$$  |\$$$$$$  |\$$$$$$  |\$$$$$$  |\$$$$$$  |      $$$$$$$$\ $$$$$$$$\ 
//  \______/  \______/  \______/  \______/  \______/       \________|\________|

// Managed by Suvraneel Bhuin, Rebecca Elisabeth Falcao and Harsh Ghodkar.


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
    bytes32 public merkleRootMentors = 0x1993360992b8b2ed8ac170359947d0c5cdcbba3c7e2ecb955aebe7bc4af96cd9;
    bytes32 public merkleRoot100Contributors = 0x4683774eeb1cd18fe11d347c9ec1fccaec5cfd2cb5284f2fd9c1575c0b0dfa0a;
    bytes32 public merkleRootContributors = 0x3831d8733937ddb50dcc100e152beb61532183b790ab7dbbef7e08638f66c4b7;
    bytes32 public merkleRootCampusAmbassadors = 0xee1dd4fa88aeaf1e156eae1325d22f407de02710d736e9f6b88d948d5165107c; 
    bytes32 public merkleRootOpenSourceAdvocates = 0x1d298d9bd556a9d14b2f01d895e87214bfe04a3ef13fc14b6b9676b8c177e3ec;
    bytes32 public merkleRootOrganizingTeam = 0xccb25a2d346cee45d946454e5c43c08bf40bb37e464675f32a635cfdb7616378;

    

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