/**
 *Submitted for verification at polygonscan.com on 2022-05-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Algoz {
    mapping(bytes32 => bool) public consumed_tokenId;
    address public owner;
    bytes32 public merkle_root;

    constructor(bytes32 initial_merkle_root) { 
        owner = msg.sender;
        merkle_root = initial_merkle_root;
    }

    function update_ownership(address new_owner) public {
        require(msg.sender == owner); // verify contract ownership
        owner = new_owner;
    }

    function update_merkle_root(bytes32 new_merkle_root) public {
        require(msg.sender == owner); // verify contract ownership
        merkle_root = new_merkle_root;
    }

    // function used to validate if a captcha is valid
    function validate_captcha(bytes32 tokenId, bytes32[] calldata proof) public {
        require(MerkleProof.verify(proof, merkle_root, tokenId)); // verify merkle proof of tokenId
        require(!consumed_tokenId[tokenId]); // verify if the tokenId has been used in the past
        consumed_tokenId[tokenId] = true;
    }
}

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