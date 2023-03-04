//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../interfaces/ISemaphoreZk3.sol";
import "../base/SemaphoreGroups.sol";
import "../interfaces/ISemaphoreVerifier.sol";

/// @title SemaphoreZK3 circles contract.
/// @dev The following code allows you to create circles, add members and allow them to double signal.
contract SemaphoreZk3 is ISemaphoreZk3, SemaphoreGroups {
    /// @dev Gets a tree depth and returns its verifier address.
    ISemaphoreVerifier internal verifier;

    /// @dev Gets a circle id and returns the circle data.
    mapping(uint256 => Circle) internal circles;

    /// @dev Initializes the Semaphore verifiers used to verify the user's ZK proofs.
    /// @param _verifier: Semaphore verifier
    constructor(ISemaphoreVerifier _verifier) {
        verifier = _verifier;
    }

    /// @dev Checks if the circle coordinator is the transaction sender.
    /// @param circleId: Id of the circle.
    modifier onlyCoordinator(uint256 circleId) {
        if (circles[circleId].coordinator != _msgSender()) {
            revert Semaphore__CallerIsNotCoordinator();
        }

        _;
    }

    /// @dev See {ISemaphoreZk3-createcircle}.
    function createCircle(
        uint256 circleId,
        address coordinator,
        uint256 merkleTreeDepth,
        string calldata contentURI
    ) public override {
        if (merkleTreeDepth < 16 || merkleTreeDepth > 32) {
            revert Semaphore__MerkleTreeDepthIsNotSupported();
        }

        if (circles[circleId].coordinator != address(0)) {
            revert Semaphore__GroupAlreadyExists();
        }

        _createGroup(circleId, merkleTreeDepth);

        circles[circleId].coordinator = coordinator;
        // don't store the nullifier hash so we can double spend the same note for now
        circles[circleId].doubleSpend = true;
        circles[circleId].contentURI = contentURI;

        emit CircleCreated(circleId, coordinator);
    }

    /// @dev See {ISemaphoreZk3-addVoter}.
    function addIdentity(
        uint256 circleId,
        uint256 identityCommitment,
        string calldata contentURI
    ) public override onlyCoordinator(circleId) {
        _addMember(circleId, identityCommitment);
        updateContentURI(circleId, contentURI);
    }

    function revokeIdentity(
        uint256 circleId,
        uint256 identityCommitment,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices,
        string calldata contentURI
    ) public override onlyCoordinator(circleId) {
        _removeMember(circleId, identityCommitment, proofSiblings, proofPathIndices);
        updateContentURI(circleId, contentURI);
    }

    function updateContentURI(uint256 circleId, string calldata contentURI) public override onlyCoordinator(circleId) {
        circles[circleId].contentURI = contentURI;
        // todo: make sure the contentURI is valid and doesn't equal the current one.
        // (assuming it's content addressable)
        emit CircleURIUpdated(circleId, contentURI);
    }

    function getContentURI(uint256 circleId) public view virtual override returns (string memory) {
        return circles[circleId].contentURI;
    }

    /// @dev See {ISemaphoreZk3-broadcastSignal}.
    function broadcastSignal(
        uint256 signal,
        uint256 nullifierHash,
        uint256 circleId,
        uint256 externalNullifier,
        uint256[8] calldata proof
    ) public override onlyCoordinator(circleId) {
        // note this will only revert if the doubleSpend flag is false even if the nullifierHash is already used
        if (circles[circleId].doubleSpend == false && circles[circleId].nullifierHashes[nullifierHash]) {
            revert Semaphore__YouAreUsingTheSameNillifierTwice();
        }

        uint256 merkleTreeDepth = getMerkleTreeDepth(circleId);
        uint256 merkleTreeRoot = getMerkleTreeRoot(circleId);

        verifier.verifyProof(merkleTreeRoot, nullifierHash, signal, externalNullifier, proof, merkleTreeDepth);

        circles[circleId].nullifierHashes[nullifierHash] = true;

        emit MembershipVerified(circleId, signal);
    }

    /// @dev See {ISemaphoreZk3-isValidProof}.
    function isValidProof(
        uint256 signal,
        uint256 nullifierHash,
        uint256 circleId,
        uint256 externalNullifier,
        uint256[8] calldata proof
    ) public view virtual override returns (bool) {
        uint256 merkleTreeDepth = getMerkleTreeDepth(circleId);
        uint256 merkleTreeRoot = getMerkleTreeRoot(circleId);

        verifier.verifyProof(merkleTreeRoot, nullifierHash, signal, externalNullifier, proof, merkleTreeDepth);
        return true;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/// @title SemaphoreVoting interface.
/// @dev Interface of SemaphoreVoting contract.
interface ISemaphoreZk3 {
    error Semaphore__CallerIsNotCoordinator();
    error Semaphore__MerkleTreeDepthIsNotSupported();
    error Semaphore__YouAreUsingTheSameNillifierTwice();

    struct Circle {
        address coordinator;
        string contentURI;
        bool doubleSpend;
        mapping(uint256 => bool) nullifierHashes;
    }

    /// @dev Emitted when a new group is created.
    /// @param circleId: Id of the group.
    /// @param coordinator: Coordinator of the group.
    event CircleCreated(uint256 circleId, address indexed coordinator);

    /// @dev Emitted when a user verifies their membership.
    /// @param circleId: Id of the group.
    /// @param signal: the signal verified.
    event MembershipVerified(uint256 indexed circleId, uint256 signal);

    /// @dev Emitted when a coordinator updateds the URI for a circle.
    /// @param circleId: Id of the group.
    /// @param contentURI: the contentURI.
    event CircleURIUpdated(uint256 indexed circleId, string contentURI);

    /// @dev Creates a poll and the associated Merkle tree/group.
    /// @param circleId: Id of the group.
    /// @param coordinator: Coordinator of the poll.
    /// @param merkleTreeDepth: Depth of the tree.
    function createCircle(
        uint256 circleId,
        address coordinator,
        uint256 merkleTreeDepth,
        string calldata contentURI
    ) external;

    function updateContentURI(uint256 circleId, string calldata contentURI) external;

    /// @dev Adds a user to a group.
    /// @param circleId: Id of the group.
    /// @param identityCommitment: Identity commitment of the group member.
    function addIdentity(
        uint256 circleId,
        uint256 identityCommitment,
        string calldata contentURI
    ) external;

    /// @dev removes a user from a gorup.
    /// @param circleId: Id of the group.
    /// @param identityCommitment: Identity commitment of the group member.
    function revokeIdentity(
        uint256 circleId,
        uint256 identityCommitment,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices,
        string calldata contentURI
    ) external;

    function getContentURI(uint256 circleId) external view returns (string memory);

    /// @dev verify an identity membership in a circle.
    /// @param signal: signal.
    /// @param nullifierHash: Nullifier hash.
    /// @param circleId: Id of the group.
    /// @param externalNullifier: External nullifier.
    /// @param proof: Private zk-proof parameters.
    function broadcastSignal(
        uint256 signal,
        uint256 nullifierHash,
        uint256 circleId,
        uint256 externalNullifier,
        uint256[8] calldata proof
    ) external;

    /// @dev verify an identity membership in a circle.
    /// @param signal: signal.
    /// @param nullifierHash: Nullifier hash.
    /// @param circleId: Id of the group.
    /// @param externalNullifier: External nullifier.
    /// @param proof: Private zk-proof parameters.
    function isValidProof(
        uint256 signal,
        uint256 nullifierHash,
        uint256 circleId,
        uint256 externalNullifier,
        uint256[8] calldata proof
    ) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../base/Pairing.sol";

/// @title SemaphoreVerifier contract interface.
interface ISemaphoreVerifier {
    struct VerificationKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] IC;
    }

    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }

    /// @dev Verifies whether a Semaphore proof is valid.
    /// @param merkleTreeRoot: Root of the Merkle tree.
    /// @param nullifierHash: Nullifier hash.
    /// @param signal: Semaphore signal.
    /// @param externalNullifier: External nullifier.
    /// @param proof: Zero-knowledge proof.
    /// @param merkleTreeDepth: Depth of the tree.
    function verifyProof(
        uint256 merkleTreeRoot,
        uint256 nullifierHash,
        uint256 signal,
        uint256 externalNullifier,
        uint256[8] calldata proof,
        uint256 merkleTreeDepth
    ) external view;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../interfaces/ISemaphoreGroups.sol";
import "@zk-kit/incremental-merkle-tree.sol/IncrementalBinaryTree.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/// @title Semaphore groups contract.
/// @dev This contract allows you to create groups, add, remove and update members.
/// You can use getters to obtain informations about groups (root, depth, number of leaves).
abstract contract SemaphoreGroups is Context, ISemaphoreGroups {
    using IncrementalBinaryTree for IncrementalTreeData;

    /// @dev Gets a group id and returns the tree data.
    mapping(uint256 => IncrementalTreeData) internal merkleTrees;

    /// @dev Creates a new group by initializing the associated tree.
    /// @param groupId: Id of the group.
    /// @param merkleTreeDepth: Depth of the tree.
    function _createGroup(uint256 groupId, uint256 merkleTreeDepth) internal virtual {
        if (getMerkleTreeDepth(groupId) != 0) {
            revert Semaphore__GroupAlreadyExists();
        }

        // The zeroValue is an implicit member of the group, or an implicit leaf of the Merkle tree.
        // Although there is a remote possibility that the preimage of
        // the hash may be calculated, using this value we aim to minimize the risk.
        uint256 zeroValue = uint256(keccak256(abi.encodePacked(groupId))) >> 8;

        merkleTrees[groupId].init(merkleTreeDepth, zeroValue);

        emit GroupCreated(groupId, merkleTreeDepth, zeroValue);
    }

    /// @dev Adds an identity commitment to an existing group.
    /// @param groupId: Id of the group.
    /// @param identityCommitment: New identity commitment.
    function _addMember(uint256 groupId, uint256 identityCommitment) internal virtual {
        if (getMerkleTreeDepth(groupId) == 0) {
            revert Semaphore__GroupDoesNotExist();
        }

        merkleTrees[groupId].insert(identityCommitment);

        uint256 merkleTreeRoot = getMerkleTreeRoot(groupId);
        uint256 index = getNumberOfMerkleTreeLeaves(groupId) - 1;

        emit MemberAdded(groupId, index, identityCommitment, merkleTreeRoot);
    }

    /// @dev Updates an identity commitment of an existing group. A proof of membership is
    /// needed to check if the node to be updated is part of the tree.
    /// @param groupId: Id of the group.
    /// @param identityCommitment: Existing identity commitment to be updated.
    /// @param newIdentityCommitment: New identity commitment.
    /// @param proofSiblings: Array of the sibling nodes of the proof of membership.
    /// @param proofPathIndices: Path of the proof of membership.
    function _updateMember(
        uint256 groupId,
        uint256 identityCommitment,
        uint256 newIdentityCommitment,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) internal virtual {
        if (getMerkleTreeDepth(groupId) == 0) {
            revert Semaphore__GroupDoesNotExist();
        }

        merkleTrees[groupId].update(identityCommitment, newIdentityCommitment, proofSiblings, proofPathIndices);

        uint256 merkleTreeRoot = getMerkleTreeRoot(groupId);
        uint256 index = proofPathIndicesToMemberIndex(proofPathIndices);

        emit MemberUpdated(groupId, index, identityCommitment, newIdentityCommitment, merkleTreeRoot);
    }

    /// @dev Removes an identity commitment from an existing group. A proof of membership is
    /// needed to check if the node to be deleted is part of the tree.
    /// @param groupId: Id of the group.
    /// @param identityCommitment: Existing identity commitment to be removed.
    /// @param proofSiblings: Array of the sibling nodes of the proof of membership.
    /// @param proofPathIndices: Path of the proof of membership.
    function _removeMember(
        uint256 groupId,
        uint256 identityCommitment,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) internal virtual {
        if (getMerkleTreeDepth(groupId) == 0) {
            revert Semaphore__GroupDoesNotExist();
        }

        merkleTrees[groupId].remove(identityCommitment, proofSiblings, proofPathIndices);

        uint256 merkleTreeRoot = getMerkleTreeRoot(groupId);
        uint256 index = proofPathIndicesToMemberIndex(proofPathIndices);

        emit MemberRemoved(groupId, index, identityCommitment, merkleTreeRoot);
    }

    /// @dev See {ISemaphoreGroups-getMerkleTreeRoot}.
    function getMerkleTreeRoot(uint256 groupId) public view virtual override returns (uint256) {
        return merkleTrees[groupId].root;
    }

    /// @dev See {ISemaphoreGroups-getMerkleTreeDepth}.
    function getMerkleTreeDepth(uint256 groupId) public view virtual override returns (uint256) {
        return merkleTrees[groupId].depth;
    }

    /// @dev See {ISemaphoreGroups-getNumberOfMerkleTreeLeaves}.
    function getNumberOfMerkleTreeLeaves(uint256 groupId) public view virtual override returns (uint256) {
        return merkleTrees[groupId].numberOfLeaves;
    }

    /// @dev Converts the path indices of a Merkle proof to the identity commitment index in the tree.
    /// @param proofPathIndices: Path of the proof of membership.
    /// @return Index of a group member.
    function proofPathIndicesToMemberIndex(uint8[] calldata proofPathIndices) private pure returns (uint256) {
        uint256 memberIndex = 0;

        for (uint8 i = uint8(proofPathIndices.length); i > 0; ) {
            if (memberIndex > 0 || proofPathIndices[i - 1] != 0) {
                memberIndex *= 2;

                if (proofPathIndices[i - 1] == 1) {
                    memberIndex += 1;
                }
            }

            unchecked {
                --i;
            }
        }

        return memberIndex;
    }
}

// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// The following Pairing library is a modified version adapted to Semaphore.
//
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Pairing {
    error Semaphore__InvalidProof();

    // The prime q in the base field F_q for G1
    uint256 constant BASE_MODULUS = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    // The prime moludus of the scalar field of G1.
    uint256 constant SCALAR_MODULUS = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

    struct G1Point {
        uint256 X;
        uint256 Y;
    }

    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint256[2] X;
        uint256[2] Y;
    }

    /// @return the generator of G1
    function P1() public pure returns (G1Point memory) {
        return G1Point(1, 2);
    }

    /// @return the generator of G2
    function P2() public pure returns (G2Point memory) {
        return
            G2Point(
                [
                    11559732032986387107991004021392285783925812861821192530917403151452391805634,
                    10857046999023057135944570762232829481370756359578518086990519993285655852781
                ],
                [
                    4082367875863433681332203403145435568316851327593401208105741076214120093531,
                    8495653923123431417604973247489272438418190587263600148770280649306958101930
                ]
            );
    }

    /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) public pure returns (G1Point memory r) {
        if (p.X == 0 && p.Y == 0) {
            return G1Point(0, 0);
        }

        // Validate input or revert
        if (p.X >= BASE_MODULUS || p.Y >= BASE_MODULUS) {
            revert Semaphore__InvalidProof();
        }

        // We know p.Y > 0 and p.Y < BASE_MODULUS.
        return G1Point(p.X, BASE_MODULUS - p.Y);
    }

    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) public view returns (G1Point memory r) {
        // By EIP-196 all input is validated to be less than the BASE_MODULUS and form points
        // on the curve.
        uint256[4] memory input;

        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;

        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
        }

        if (!success) {
            revert Semaphore__InvalidProof();
        }
    }

    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint256 s) public view returns (G1Point memory r) {
        // By EIP-196 the values p.X and p.Y are verified to less than the BASE_MODULUS and
        // form a valid point on the curve. But the scalar is not verified, so we do that explicitelly.
        if (s >= SCALAR_MODULUS) {
            revert Semaphore__InvalidProof();
        }

        uint256[3] memory input;

        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;

        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
        }

        if (!success) {
            revert Semaphore__InvalidProof();
        }
    }

    /// Asserts the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should succeed
    function pairingCheck(G1Point[] memory p1, G2Point[] memory p2) public view {
        // By EIP-197 all input is verified to be less than the BASE_MODULUS and form elements in their
        // respective groups of the right order.
        if (p1.length != p2.length) {
            revert Semaphore__InvalidProof();
        }

        uint256 elements = p1.length;
        uint256 inputSize = elements * 6;
        uint256[] memory input = new uint256[](inputSize);

        for (uint256 i = 0; i < elements; i++) {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }

        uint256[1] memory out;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
        }

        if (!success || out[0] != 1) {
            revert Semaphore__InvalidProof();
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/// @title SemaphoreGroups contract interface.
interface ISemaphoreGroups {
    error Semaphore__GroupDoesNotExist();
    error Semaphore__GroupAlreadyExists();

    /// @dev Emitted when a new group is created.
    /// @param groupId: Id of the group.
    /// @param merkleTreeDepth: Depth of the tree.
    /// @param zeroValue: Zero value of the tree.
    event GroupCreated(uint256 indexed groupId, uint256 merkleTreeDepth, uint256 zeroValue);

    /// @dev Emitted when a new identity commitment is added.
    /// @param groupId: Group id of the group.
    /// @param index: Identity commitment index.
    /// @param identityCommitment: New identity commitment.
    /// @param merkleTreeRoot: New root hash of the tree.
    event MemberAdded(uint256 indexed groupId, uint256 index, uint256 identityCommitment, uint256 merkleTreeRoot);

    /// @dev Emitted when an identity commitment is updated.
    /// @param groupId: Group id of the group.
    /// @param index: Identity commitment index.
    /// @param identityCommitment: Existing identity commitment to be updated.
    /// @param newIdentityCommitment: New identity commitment.
    /// @param merkleTreeRoot: New root hash of the tree.
    event MemberUpdated(
        uint256 indexed groupId,
        uint256 index,
        uint256 identityCommitment,
        uint256 newIdentityCommitment,
        uint256 merkleTreeRoot
    );

    /// @dev Emitted when a new identity commitment is removed.
    /// @param groupId: Group id of the group.
    /// @param index: Identity commitment index.
    /// @param identityCommitment: Existing identity commitment to be removed.
    /// @param merkleTreeRoot: New root hash of the tree.
    event MemberRemoved(uint256 indexed groupId, uint256 index, uint256 identityCommitment, uint256 merkleTreeRoot);

    /// @dev Returns the last root hash of a group.
    /// @param groupId: Id of the group.
    /// @return Root hash of the group.
    function getMerkleTreeRoot(uint256 groupId) external view returns (uint256);

    /// @dev Returns the depth of the tree of a group.
    /// @param groupId: Id of the group.
    /// @return Depth of the group tree.
    function getMerkleTreeDepth(uint256 groupId) external view returns (uint256);

    /// @dev Returns the number of tree leaves of a group.
    /// @param groupId: Id of the group.
    /// @return Number of tree leaves.
    function getNumberOfMerkleTreeLeaves(uint256 groupId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {PoseidonT3} from "./Hashes.sol";

// Each incremental tree has certain properties and data that will
// be used to add new leaves.
struct IncrementalTreeData {
    uint256 depth; // Depth of the tree (levels - 1).
    uint256 root; // Root hash of the tree.
    uint256 numberOfLeaves; // Number of leaves of the tree.
    mapping(uint256 => uint256) zeroes; // Zero hashes used for empty nodes (level -> zero hash).
    // The nodes of the subtrees used in the last addition of a leaf (level -> [left node, right node]).
    mapping(uint256 => uint256[2]) lastSubtrees; // Caching these values is essential to efficient appends.
}

/// @title Incremental binary Merkle tree.
/// @dev The incremental tree allows to calculate the root hash each time a leaf is added, ensuring
/// the integrity of the tree.
library IncrementalBinaryTree {
    uint8 internal constant MAX_DEPTH = 32;
    uint256 internal constant SNARK_SCALAR_FIELD =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    /// @dev Initializes a tree.
    /// @param self: Tree data.
    /// @param depth: Depth of the tree.
    /// @param zero: Zero value to be used.
    function init(
        IncrementalTreeData storage self,
        uint256 depth,
        uint256 zero
    ) public {
        require(zero < SNARK_SCALAR_FIELD, "IncrementalBinaryTree: leaf must be < SNARK_SCALAR_FIELD");
        require(depth > 0 && depth <= MAX_DEPTH, "IncrementalBinaryTree: tree depth must be between 1 and 32");

        self.depth = depth;

        for (uint8 i = 0; i < depth; ) {
            self.zeroes[i] = zero;
            zero = PoseidonT3.poseidon([zero, zero]);

            unchecked {
                ++i;
            }
        }

        self.root = zero;
    }

    /// @dev Inserts a leaf in the tree.
    /// @param self: Tree data.
    /// @param leaf: Leaf to be inserted.
    function insert(IncrementalTreeData storage self, uint256 leaf) public {
        uint256 depth = self.depth;

        require(leaf < SNARK_SCALAR_FIELD, "IncrementalBinaryTree: leaf must be < SNARK_SCALAR_FIELD");
        require(self.numberOfLeaves < 2**depth, "IncrementalBinaryTree: tree is full");

        uint256 index = self.numberOfLeaves;
        uint256 hash = leaf;

        for (uint8 i = 0; i < depth; ) {
            if (index & 1 == 0) {
                self.lastSubtrees[i] = [hash, self.zeroes[i]];
            } else {
                self.lastSubtrees[i][1] = hash;
            }

            hash = PoseidonT3.poseidon(self.lastSubtrees[i]);
            index >>= 1;

            unchecked {
                ++i;
            }
        }

        self.root = hash;
        self.numberOfLeaves += 1;
    }

    /// @dev Updates a leaf in the tree.
    /// @param self: Tree data.
    /// @param leaf: Leaf to be updated.
    /// @param newLeaf: New leaf.
    /// @param proofSiblings: Array of the sibling nodes of the proof of membership.
    /// @param proofPathIndices: Path of the proof of membership.
    function update(
        IncrementalTreeData storage self,
        uint256 leaf,
        uint256 newLeaf,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) public {
        require(newLeaf != leaf, "IncrementalBinaryTree: new leaf cannot be the same as the old one");
        require(newLeaf < SNARK_SCALAR_FIELD, "IncrementalBinaryTree: new leaf must be < SNARK_SCALAR_FIELD");
        require(
            verify(self, leaf, proofSiblings, proofPathIndices),
            "IncrementalBinaryTree: leaf is not part of the tree"
        );

        uint256 depth = self.depth;
        uint256 hash = newLeaf;
        uint256 updateIndex;

        for (uint8 i = 0; i < depth; ) {
            updateIndex |= uint256(proofPathIndices[i]) << uint256(i);

            if (proofPathIndices[i] == 0) {
                if (proofSiblings[i] == self.lastSubtrees[i][1]) {
                    self.lastSubtrees[i][0] = hash;
                }

                hash = PoseidonT3.poseidon([hash, proofSiblings[i]]);
            } else {
                if (proofSiblings[i] == self.lastSubtrees[i][0]) {
                    self.lastSubtrees[i][1] = hash;
                }

                hash = PoseidonT3.poseidon([proofSiblings[i], hash]);
            }

            unchecked {
                ++i;
            }
        }
        require(updateIndex < self.numberOfLeaves, "IncrementalBinaryTree: leaf index out of range");

        self.root = hash;
    }

    /// @dev Removes a leaf from the tree.
    /// @param self: Tree data.
    /// @param leaf: Leaf to be removed.
    /// @param proofSiblings: Array of the sibling nodes of the proof of membership.
    /// @param proofPathIndices: Path of the proof of membership.
    function remove(
        IncrementalTreeData storage self,
        uint256 leaf,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) public {
        update(self, leaf, self.zeroes[0], proofSiblings, proofPathIndices);
    }

    /// @dev Verify if the path is correct and the leaf is part of the tree.
    /// @param self: Tree data.
    /// @param leaf: Leaf to be removed.
    /// @param proofSiblings: Array of the sibling nodes of the proof of membership.
    /// @param proofPathIndices: Path of the proof of membership.
    /// @return True or false.
    function verify(
        IncrementalTreeData storage self,
        uint256 leaf,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) private view returns (bool) {
        require(leaf < SNARK_SCALAR_FIELD, "IncrementalBinaryTree: leaf must be < SNARK_SCALAR_FIELD");
        uint256 depth = self.depth;
        require(
            proofPathIndices.length == depth && proofSiblings.length == depth,
            "IncrementalBinaryTree: length of path is not correct"
        );

        uint256 hash = leaf;

        for (uint8 i = 0; i < depth; ) {
            require(
                proofSiblings[i] < SNARK_SCALAR_FIELD,
                "IncrementalBinaryTree: sibling node must be < SNARK_SCALAR_FIELD"
            );

            require(
                proofPathIndices[i] == 1 || proofPathIndices[i] == 0,
                "IncrementalBinaryTree: path index is neither 0 nor 1"
            );

            if (proofPathIndices[i] == 0) {
                hash = PoseidonT3.poseidon([hash, proofSiblings[i]]);
            } else {
                hash = PoseidonT3.poseidon([proofSiblings[i], hash]);
            }

            unchecked {
                ++i;
            }
        }

        return hash == self.root;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library PoseidonT3 {
    function poseidon(uint256[2] memory) public pure returns (uint256) {}
}

library PoseidonT6 {
    function poseidon(uint256[5] memory) public pure returns (uint256) {}
}