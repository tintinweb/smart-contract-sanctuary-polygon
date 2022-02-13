/**
 *Submitted for verification at polygonscan.com on 2022-02-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/access/AccessControl.sol";




contract EmblemRegistry {


    // true if merkle root has been stored
    mapping(bytes32 => bool) private _merkleRoots;

    // maps BadgeDefinitionNumber to registries of winners (1 if badge has been won, 0 if not)
    mapping(uint256 => mapping(address => uint256)) private _balances;

    constructor() {
        // _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function postMerkleRoot(
        bytes32 root
    ) public {
        // require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not EmblemRegistry admin");
        _merkleRoots[root] = true;
    }

    function mint(
        address winner,
        uint8 badgeDefinitionNumber,
        bytes32[] memory merkleProof,
        uint256[] memory positions,
        bytes32 merkleRoot
    ) public {
        // require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not EmblemRegistry admin");
        require(_merkleRoots[merkleRoot] == true, "Merkle root not found");
        require(verify(merkleProof, positions, merkleRoot, hashBadge(winner, badgeDefinitionNumber)), "Invalid merkle proof");
        _balances[badgeDefinitionNumber][winner] = 1;
    }
    function burn(
        address winner,
        uint256 badgeDefinitionNumber
    ) public {
        // require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not EmblemRegistry admin");
        _balances[badgeDefinitionNumber][winner] = 0;
    }

    function balanceOf(
        address owner,
        uint256 id
    ) external view returns (uint256) {
        return _balances[id][owner];
    }

    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. The
     * positions parameter defines sorting.
     */
    function verify(
        bytes32[] memory proof,
        uint256[] memory positions,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (positions[i] == 1) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }

    function hashBadge(address winner, uint8 badgeDefinitionNumber) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(winner, badgeDefinitionNumber));
    }
}