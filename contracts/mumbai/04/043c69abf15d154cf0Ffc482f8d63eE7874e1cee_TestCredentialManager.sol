// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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

interface ICredentialHandler {
    /// @dev Invalidates a credential, making it no longer solvable.
    /// @param credentialId: Id of the credential to invalidate.
    function invalidateCredential(
        uint256 credentialId
    ) external;

    /// @dev Returns the data that defines the credential as per the credential manager.
    /// @param credentialId: Id of the credential.
    /// @return bytes, credential data.
    function getCredentialData(
        uint256 credentialId
    ) external view returns (bytes memory);

    /// @dev Returns the data that defines the credential as per the credential manager.
    /// @param credentialId: Id of the credential.
    /// @return bytes, credential data.
    function getCredentialAdmin(
        uint256 credentialId
    ) external view returns (address);

    /// @dev Returns whether the credential exists, that is, if it has been created.
    /// @param credentialId: Id of the credential.
    /// @return bool, whether the credential exists.
    function credentialExists(
        uint256 credentialId
    ) external view returns (bool);

    /// @dev Returns whether the credential is valid, that is, if it has been created and not invalidated.
    /// @param credentialId: Id of the credential.
    /// @return bool, whether the credential is valid.
    function credentialIsValid(
        uint256 credentialId
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "./ICredentialHandler.sol";
import { CredentialState } from "../libs/Structs.sol";

/// @title Credential Manager interface.
/// @dev Interface of a CredentialManager contract.
interface ICredentialManager is ICredentialHandler, IERC165 {
    error CallerIsNotTheCredentialsRegistry();
    error CallerIsNotTheCredentialAdmin();
    error CredentialWasInvalidated();
    error MerkleTreeDepthIsNotSupported();

    /// @dev Emitted when a credential is invalidated by its admin.
    /// @param credentialId: Id of the credential.
    event CredentialInvalidated(uint256 indexed credentialId);

    /// @dev Emitted when a user's grade commitment is added to the grade tree.
    /// @param credentialId: Id of the credential.
    /// @param index: Commitment index.
    /// @param gradeCommitment: New identity commitment added to the credentials tree.
    /// @param gradeTreeRoot: New root hash of the grade tree.
    event GradeMemberAdded(uint256 indexed credentialId, uint256 index, uint256 gradeCommitment, uint256 gradeTreeRoot);

    /// @dev Emitted when a credential is gained and the user's identity commitment is added to the credential tree.
    /// @param credentialId: Id of the credential.
    /// @param index: Commitment index.
    /// @param identityCommitment: New identity commitment added to the credentials tree.
    /// @param credentialsTreeRoot: New root hash of the credentials tree.
    event CredentialsMemberAdded(uint256 indexed credentialId, uint256 index, uint256 identityCommitment, uint256 credentialsTreeRoot);

    /// @dev Emitted when a a credential is not gained and the user's identity commitment is added to the no-credential tree.
    /// @param credentialId: Id of the credential.
    /// @param index: Commitment index.
    /// @param identityCommitment: New identity commitment added to the credentials tree.
    /// @param noCredentialsTreeRoot: New root hash of the credentials tree.
    event NoCredentialsMemberAdded(uint256 indexed credentialId, uint256 index, uint256 identityCommitment, uint256 noCredentialsTreeRoot);

    /// @dev Emitted when a grade group member is updated.
    /// @param credentialId: Id of the credential.
    /// @param gradeTreeIndex: Grade commitment index within the grade tree.
    /// @param gradeCommitment: Existing grade commitment in the grade tree to be updated.
    /// @param newGradeCommitment: New grade commitment.
    /// @param gradeTreeRoot: New root hash of the grade tree.
    event GradeMemberUpdated(
        uint256 indexed credentialId,
        uint256 gradeTreeIndex,
        uint256 gradeCommitment,
        uint256 newGradeCommitment,
        uint256 gradeTreeRoot
    );

    /// @dev Emitted when a credentials group member is updated.
    /// @param credentialId: Id of the credential.
    /// @param credentialsTreeIndex: Identity commitment index within the credentials tree.
    /// @param identityCommitment: Existing identity commitment in the credentials tree to be updated.
    /// @param newIdentityCommitment: New identity commitment.
    /// @param credentialsTreeRoot: New root hash of the credentials tree.
    event CredentialMemberUpdated(
        uint256 indexed credentialId,
        uint256 credentialsTreeIndex,
        uint256 identityCommitment,
        uint256 newIdentityCommitment,
        uint256 credentialsTreeRoot
    );

    /// @dev Emitted when a no-credentials group member is updated.
    /// @param credentialId: Id of the credential.
    /// @param noCredentialsTreeIndex: Identity commitment index within the no-credentials tree.
    /// @param identityCommitment: Existing identity commitment in the no-credentials tree to be updated.
    /// @param newIdentityCommitment: New identity commitment.
    /// @param noCredentialsTreeRoot: New root hash of the no-credentials tree.
    event NoCredentialMemberUpdated(
        uint256 indexed credentialId,
        uint256 noCredentialsTreeIndex,
        uint256 identityCommitment,
        uint256 newIdentityCommitment,
        uint256 noCredentialsTreeRoot
    );

    /// @dev Emitted when a new grade commitment within the grade tree is removed.
    /// @param credentialId: Id of the credential.
    /// @param gradeTreeIndex: Grade commitment index within the grade tree.
    /// @param gradeCommitment: Existing grade commitment in the grade tree to be removed.
    /// @param gradeTreeRoot: New root hash of the grade tree.
    event GradeMemberRemoved(
        uint256 indexed credentialId,
        uint256 gradeTreeIndex,
        uint256 gradeCommitment,
        uint256 gradeTreeRoot
    );

    /// @dev Emitted when a new identity commitment within the credentials tree is removed.
    /// @param credentialId: Id of the credential.
    /// @param credentialsTreeIndex: Identity commitment index within the credentials tree.
    /// @param identityCommitment: Existing identity commitment in the credentials tree to be removed.
    /// @param credentialsTreeRoot: New root hash of the credentials tree.
    event CredentialMemberRemoved(
        uint256 indexed credentialId,
        uint256 credentialsTreeIndex,
        uint256 identityCommitment,
        uint256 credentialsTreeRoot
    );

    /// @dev Emitted when a new identity commitment within the no-credentials tree is removed.
    /// @param credentialId: Id of the credential.
    /// @param noCredentialsTreeIndex: Identity commitment index within the no-credentials tree.
    /// @param identityCommitment: Existing identity commitment in the no-credentials tree to be removed.
    /// @param noCredentialsTreeRoot: New root hash of the no-credentials tree.
    event NoCredentialMemberRemoved(
        uint256 indexed credentialId,
        uint256 noCredentialsTreeIndex,
        uint256 identityCommitment,
        uint256 noCredentialsTreeRoot
    );

    /// @dev Defines a new credential as per the credential manager specifications.
    /// @param credentialId: Id of the credential.
    /// @param treeDepth: Depth of the trees that define the credential state.
    /// @param credentialData: Data that defines the credential, as per the credential manager specifications.
    function createCredential(
        uint256 credentialId,
        uint256 treeDepth,
        bytes calldata credentialData
    ) external returns (CredentialState memory);

    /// @dev Updates a credential as per the credential manager specifications.
    /// @param credentialId: Id of the credential.
    /// @param credentialState: Current state of the credential.
    /// @param credentialUpdate: Data that defines the credential update, as per the credential manager specifications.
    /// @return CredentialState, new state of the credential.
    function updateCredential(
        uint256 credentialId,
        CredentialState calldata credentialState,
        bytes calldata credentialUpdate
    ) external returns (CredentialState memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@semaphore-protocol/contracts/interfaces/ISemaphoreGroups.sol";
import "./ICredentialHandler.sol";
import { CredentialParameters, CredentialRating, CredentialState } from "../libs/Structs.sol";

/// @title Credentials Registry interface.
/// @dev Interface of a CredentialsRegistry contract.
interface ICredentialsRegistry is ICredentialHandler, ISemaphoreGroups {
    error CredentialIdAlreadyExists();
    error CredentialTypeDoesNotExist();
    error CredentialDoesNotExist();
    error CredentialTypeAlreadyDefined();
    error InvalidCredentialManagerAddress();

    error InvalidTreeDepth();
    error InvalidRating();

    error MerkleTreeRootIsNotPartOfTheGroup();
    error MerkleTreeRootIsExpired();
    error UsingSameNullifierTwice();

    /// @dev Emitted when a credential is created.
    /// @param credentialId: Id of the credential.
    /// @param credentialType: Unique identifier that links to the credential manager that will define its behavior.
    /// @param merkleTreeDepth: Depth of the tree.
    event CredentialCreated(uint256 indexed credentialId, uint256 indexed credentialType, uint256 merkleTreeDepth);

    /// @dev Emitted when a rating is given to a credential and its issuer.
    /// @param credentialId: Id of the credential.
    /// @param admin: Address that controls the credential.
    /// @param rating: Rating given to the credential issuer for this test.
    /// @param comment: Comment given to the credential issuer for this test.
    event NewCredentialRating(uint256 indexed credentialId, address indexed admin, uint256 rating, string comment);

    /// @dev Creates a new credential, defining the starting credential state, and calls the relevant credential manager define it.
    /// @param credentialId: Unique identifier for this credential.
    /// @param treeDepth: Depth of the trees that define the credential state.
    /// @param credentialType: Unique identifier that links to the credential manager that will define its behavior.
    /// @param merkleTreeDuration: Maximum time that an expired Merkle root can still be used to generate proofs of membership for this credential.
    /// @param credentialData: Data that defines the credential, as per the credential manager specifications.
    /// @param credentialURI: External resource containing more information about the credential.
    function createCredential(
        uint256 credentialId,
        uint256 treeDepth,
        uint256 credentialType,
        uint256 merkleTreeDuration,
        bytes calldata credentialData,
        string calldata credentialURI
    ) external;

    /// @dev Calls the relevant credential manager to update the credential.
    /// @param credentialId: Id of the credential.
    /// @param credentialUpdate: Data that defines the credential update, as per the credential manager specifications.
    function updateCredential(
        uint256 credentialId,
        bytes calldata credentialUpdate
    ) external;

    /// @dev Defines a new credential type by specifying the contract address of the credential manager that will define it.
    /// @param credentialType: Unique identifier of the new credential type.
    /// @param credentialManager: ICredentialManager compliant smart contract.
    function defineCredentialType(
        uint256 credentialType,
        address credentialManager
    ) external;

    /// @dev Proves ownership of a credential and gives a rating to a credential and its issuer.
    /// @param credentialId: Id of the test for which the rating is being done.
    /// @param credentialsTreeRoot: Root of the credentials Merkle tree.
    /// @param nullifierHash: Nullifier hash.
    /// @param proof: Semaphore zero-knowledge proof.
    /// @param rating: Rating given to the credential issuer for this test, 0-100.
    /// @param comment: A comment given to the credential issuer.
    function rateCredential(
        uint256 credentialId,
        uint256 credentialsTreeRoot,
        uint256 nullifierHash,
        uint256[8] calldata proof,
        uint128 rating,
        string calldata comment
    ) external;

    /// @dev Verifies whether a Semaphore credential ownership/non-ownership proof is valid, and voids.
    /// the nullifierHash in the process. This way, the same proof will not be valid twice.
    /// @param credentialId: Id of the credential for which the ownership proof is being done.
    /// @param merkleTreeRoot: Root of the credentials Merkle tree.
    /// @param nullifierHash: Nullifier hash.
    /// @param signal: Semaphore signal.
    /// @param externalNullifier: External nullifier.
    /// @param proof: Zero-knowledge proof.
    function verifyCredentialOwnershipProof(
        uint256 credentialId,
        uint256 merkleTreeRoot,
        uint256 nullifierHash,
        uint256 signal,
        uint256 externalNullifier,
        uint256[8] calldata proof
    ) external;

    /// @dev Verifies whether a grade claim proof is valid, and voids the nullifierHash in the process.
    /// This way, the same proof will not be valid twice.
    /// @param credentialId: Id of the credential for which the ownership proof is being done.
    /// @param gradeTreeRoot: Root of the grade Merkle tree.
    /// @param nullifierHash: Nullifier hash.
    /// @param gradeThreshold: Grade threshold the user claims to have obtained.
    /// @param signal: Semaphore signal.
    /// @param externalNullifier: external nullifier.
    /// @param proof: Zero-knowledge proof.
    function verifyGradeClaimProof(
        uint256 credentialId,
        uint256 gradeTreeRoot,
        uint256 nullifierHash,
        uint256 gradeThreshold,
        uint256 signal,
        uint256 externalNullifier,
        uint256[8] calldata proof
    ) external;

    /// @dev Returns the type of the credential.
    /// @param credentialId: Id of the credential.
    /// @return uint256, credential type.
    function getCredentialType(
        uint256 credentialId
    ) external view returns (uint256);

    /// @dev Returns the manager of the credential.
    /// @param credentialId: Id of the credential.
    /// @return address, ITestManager compliant address that manages this credential.
    function getCredentialManager(
        uint256 credentialId
    ) external view returns (address);

    /// @dev Returns an external resource containing more information about the credential.
    /// @param credentialId: Id of the credential.
    /// @return string, the credential URI.
    function getCredentialURI(
        uint256 credentialId
    ) external view returns (string memory);

    /// @dev Returns the average rating that a credential has obtained.
    /// @param credentialId: Id of the credential.
    /// @return uint256, average rating the test received.
    function getCredentialAverageRating(
        uint256 credentialId
    ) external view returns(uint256);

    /// @dev Returns the timestamp when the given Merkle root was validated for a given credential.
    /// @param credentialId: Id of the credential.
    /// @param merkleRoot: Merkle root of interest.
    /// @return uint256, validation timestamp for the given `merkleRoot`.
    function getMerkleRootCreationDate(
        uint256 credentialId, 
        uint256 merkleRoot
    ) external view returns (uint256);

    /// @dev Returns whether a nullifier hash was already voided for a given credential.
    /// @param credentialId: Id of the credential.
    /// @param nullifierHash: Nullifier hash of interest.
    /// @return bool, whether the `nullifierHash` was already voided.
    function wasNullifierHashUsed(
        uint256 credentialId, 
        uint256 nullifierHash
    ) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

library PairingLib {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() internal pure returns (G2Point memory) {
        // Original code point
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );

    /*
            // Changed by Jordi point
            return G2Point(
                [10857046999023057135944570762232829481370756359578518086990519993285655852781,
                11559732032986387107991004021392285783925812861821192530917403151452391805634],
                [8495653923123431417604973247489272438418190587263600148770280649306958101930,
                4082367875863433681332203403145435568316851327593401208105741076214120093531]
            );
    */
    }
    /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) internal pure returns (G1Point memory r) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-add-failed");
    }
    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"pairing-mul-failed");
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length,"pairing-lengths-failed");
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-opcode-failed");
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}

// TODO update to new Semaphore verifier:
// https://github.com/semaphore-protocol/semaphore/pull/96
// by using the following template:
// https://github.com/semaphore-protocol/semaphore/blob/main/packages/contracts/snarkjs-templates/verifier_groth16.sol.ejs

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @dev Performs the Poseidon hash for two inputs.
library PoseidonT3 {
    function poseidon(uint256[2] memory) public pure returns (uint256) {}
}

/// @dev Performs the Poseidon hash for three inputs.
library PoseidonT4 {
    function poseidon(uint256[3] memory) public pure returns (uint256) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// It defines the current state of the credential.
struct CredentialState {
    /// Leaf index of the next empty grade tree leaf.
    uint80 gradeTreeIndex;
    /// Leaf index of the next empty credentials tree leaf.
    uint80 credentialsTreeIndex;
    /// Leaf index of the next empty no-credentials tree leaf.
    uint80 noCredentialsTreeIndex;
    /// Root hash of the grade tree.
    uint256 gradeTreeRoot;
    /// Root hash of the credentials tree.
    uint256 credentialsTreeRoot;
    /// Root hash of the no credentials tree root.
    uint256 noCredentialsTreeRoot;
}

/// It specifies the parameters that define a credential.
struct CredentialParameters {
    /// Depth of the trees making up the different groups.
    uint256 treeDepth;
    /// Type of the credential, which is mapped to the corresponding manager.
    uint256 credentialType;
    /// Merkle root validity duration in minutes.
    uint256 merkleTreeDuration;
    /// Creation timestamp for the different Merkle roots the credential groups gets.
    mapping(uint256 => uint256) merkleRootCreationDates;
    /// Used nullifier hashes when generating Semaphore inclusion/grade claim proofs.
    mapping(uint256 => bool) nullifierHashes;
}

/// It defines the credential rating
struct CredentialRating {
    /// Sum of all the ratings the credential has received.
    uint128 totalRating;
    /// Number of times the credential has been rated.
    uint128 nRatings;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";
import "../../interfaces/ICredentialsRegistry.sol";
import "../interfaces/ITestVerifier.sol";
import "../interfaces/ITestCredentialManager.sol";
import { TestCredential, TestCredentialHashes } from "../libs/Structs.sol";

abstract contract TestCredentialManagerBase is ITestCredentialManager, Context {
    uint256 constant MAX_GRADE = 100;

    /// @dev Gets a credential id and returns the credential parameters
    mapping(uint256 => TestCredential) public testCredentials;
    /// @dev Gets a credential id and returns the test hashes
    mapping(uint256 => TestCredentialHashes) public testCredentialsHashes;

    /// @dev CredentialsRegistry smart contract
    ICredentialsRegistry public credentialsRegistry;
    
    /// @dev TestVerifier smart contract
    ITestVerifier public testVerifier;

    /// @dev Enforces that the Credentials Registry is the transaction sender.
    /// @param credentialId: Id of the credential.
    modifier onlyCredentialsRegistry(uint256 credentialId) {
        if (address(credentialsRegistry) != _msgSender()) {
            revert CallerIsNotTheCredentialsRegistry();
        }
        _;
    }

    /// @dev Enforces that the credential admin is the transaction sender.
    /// @param credentialId: Id of the credential.
    modifier onlyCredentialAdmin(uint256 credentialId) {
        if (testCredentials[credentialId].admin != tx.origin) {
            revert CallerIsNotTheCredentialAdmin();
        }
        _;
    }

    /// @dev Enforces that this test credential exists, that is, if it is managed by the test credential manager.
    /// @param credentialId: Id of the credential.
    modifier onlyExistingTestCredentials(uint256 credentialId) {
        if (credentialsRegistry.getCredentialManager(credentialId) != address(this)) {
            revert TestCredentialDoesNotExist();
        }
        credentialsRegistry.credentialExists(credentialId);
        _;
    }

    /// @dev Enforces that the test credential was not invalidated.
    /// Note that test credentials that are not defined yet are also not invalidated.
    /// @param credentialId: Id of the credential.
    modifier onlyValidTestCredentials(uint256 credentialId) {
        if (testCredentials[credentialId].minimumGrade == 255) {
            revert CredentialWasInvalidated();
        }
        _;
    }

    /// @dev See {ICredentialHandler-invalidateCredential}
    function invalidateCredential(
        uint256 credentialId
    ) 
        external override 
        onlyExistingTestCredentials(credentialId) 
        onlyValidTestCredentials(credentialId) 
        onlyCredentialsRegistry(credentialId) 
        onlyCredentialAdmin(credentialId) 
    {
        testCredentials[credentialId].minimumGrade = 255;

        emit CredentialInvalidated(credentialId);
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == type(ICredentialManager).interfaceId;
    }

    /// @dev Validates the TestCredential struct
    function _validateTestCredential(
        uint256 credentialId,
        TestCredential memory testCredential
    ) internal view {
        if (testCredential.testHeight < 4 || testCredential.testHeight > 6) {
            revert TestDepthIsNotSupported();
        }

        // Ensure the required credential exists, if it was specified
        if (testCredential.requiredCredential != 0) {
            if (testCredential.requiredCredential == credentialId) {
                revert CannotRequireSameCredential();
            }

            if (!credentialsRegistry.credentialExists(testCredential.requiredCredential)) {
                revert RequiredCredentialDoesNotExist();
            }
        }

        // Ensure that the required credential was specified if the grade threshold is given
        if (testCredential.requiredCredentialGradeThreshold > 0 && testCredential.requiredCredential == 0) {
            revert GradeRestrictedTestsMustSpecifyRequiredCredential();
        }

        if (testCredential.timeLimit < block.timestamp && testCredential.timeLimit != 0) {
            revert TimeLimitIsInThePast();
        }

        if (testCredential.nQuestions > 2 ** testCredential.testHeight || testCredential.nQuestions == 0 ) {
            revert InvalidNumberOfQuestions();
        }

        if (testCredential.minimumGrade > MAX_GRADE) {
            revert InvalidMinimumGrade();
        }

        if (testCredential.multipleChoiceWeight > 100) {
            revert InvalidMultipleChoiceWeight();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../interfaces/ICredentialManager.sol";

interface ITestCredentialManager is ICredentialManager {
    error TestDepthIsNotSupported();
    error CannotRequireSameCredential();
    error RequiredCredentialDoesNotExist();
    error GradeRestrictedTestsMustSpecifyRequiredCredential();
    error TimeLimitIsInThePast();
    error InvalidNumberOfQuestions();
    error InvalidMinimumGrade();
    error InvalidMultipleChoiceWeight();

    error TestCredentialDoesNotExist();
    error TimeLimitReached();
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../libs/PairingLib.sol";

/// @title Test Verifier interface.
/// @dev Interface of Test Verifier contract.
interface ITestVerifier {
    error InvalidProof();
    
    struct VerifyingKey {
        PairingLib.G1Point alfa1;
        PairingLib.G2Point beta2;
        PairingLib.G2Point gamma2;
        PairingLib.G2Point delta2;
        PairingLib.G1Point[] IC;
    }
    
    struct Proof {
        PairingLib.G1Point A;
        PairingLib.G2Point B;
        PairingLib.G1Point C;
    }

    /// @dev Verifies a Test proof.
    /// @param proof: SNARk proof.
    /// @param input: public inputs for the proof, these being:
    ///     - identityCommitmentIndex
    ///     - identityCommitment
    ///     - oldIdentityTreeRoot
    ///     - newIdentityTreeRoot
    ///     - gradeCommitmentIndex
    ///     - gradeCommitment
    ///     - oldGradeTreeRoot
    ///     - newGradeTreeRoot
    ///     - testRoot
    ///     - testParameters
    /// @param testHeight: height of the trees that define the test.
    function verifyProof(
        uint256[8] calldata proof,
        uint256[10] memory input,
        uint8 testHeight
    ) external view;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// Defines the test parameters that are necessary to initialize a new credential test.
struct TestCredential {
    /// Height of the trees that define the test.
    uint8 testHeight;
    /// Out of 100, minimum total grade the user must get to obtain the credential.
    uint8 minimumGrade;
    /// Out of 100, contribution of the multiple choice component towards the total grade:
    /// pure multiple choice tests will have 100, pure open answer tests will have 0.
    uint8 multipleChoiceWeight;
    /// Number of open answer questions the test has -- must be set to 1 for pure multiple choice tests.
    uint8 nQuestions;
    /// Unix time limit after which it is not possible to obtain this credential -- set 0 for unlimited.
    uint32 timeLimit;
    /// Address that controls this credential.
    address admin;
    /// The testId of the credential that needs to be obtained before this one -- set 0 for unrestricted.
    uint256 requiredCredential;
    /// Minimum grade that must be obtained for the required credential -- set 0 for unrestricted.
    uint256 requiredCredentialGradeThreshold;
    /// Root of the multiple choice Merkle tree, where each leaf is the correct choice out of the given ones.
    uint256 multipleChoiceRoot;
    /// Root of the open answers Merkle tree, where each leaf is the hash of the corresponding correct answer.
    uint256 openAnswersHashesRoot;
}

/// Defines the hashes that are computed at instantiation time
struct TestCredentialHashes {
    /// The test root is the result of hashing together the multiple choice root and the open answers root.
    uint256 testRoot;
    /// The test parameters are the result of hashing together the minimum grade, multiple choice weight and number of questions.
    uint256 testParameters;
    /// The non passing test parameters are the result of hashing together a minimum grade set to zero, multiple choice weight and number of questions.
    uint256 nonPassingTestParameters;
}

/// It defines all the test parameters.
struct CredentialData {
    /// Height of the trees that define the test.
    uint8 testHeight;
    /// Out of 100, minimum total grade the user must get to obtain the credential.
    uint8 minimumGrade;  
    /// Out of 100, contribution of the multiple choice component towards the total grade:
    /// pure multiple choice tests will have 100, pure open answer tests will have 0.
    uint8 multipleChoiceWeight;
    /// Number of open answer questions the test has -- must be set to 1 for pure multiple choice tests.
    uint8 nQuestions;
    /// Unix time limit after which it is not possible to obtain this credential -- set 0 for unlimited.
    uint32 timeLimit;
    /// Address that controls this credential.
    address admin;
    /// The testId of the credential that needs to be obtained before this one -- set 0 for unrestricted.
    uint256 requiredCredential;
    /// Minimum grade that must be obtained for the required credential -- set 0 for unrestricted.
    uint256 requiredCredentialGradeThreshold;
    /// Root of the multiple choice Merkle tree, where each leaf is the correct choice out of the given ones.
    uint256 multipleChoiceRoot;
    /// Root of the open answers Merkle tree, where each leaf is the hash of the corresponding correct answer.
    uint256 openAnswersHashesRoot;
    /// The test root is the result of hashing together the multiple choice root and the open answers root.
    uint256 testRoot;
    /// The test parameters are the result of hashing together the minimum grade, multiple choice weight and number of questions.
    uint256 testParameters;
    /// The non passing test parameters are the result of hashing together a minimum grade set to zero, multiple choice weight and number of questions.
    uint256 nonPassingTestParameters;
}

/// Defines the parameters that make up a solution proof to a credential test.
struct TestFullProof {
    /// New identity commitment to add to the identity tree (credentials or no credentials tree).
    uint256 identityCommitment;
    /// New root of the identity tree result of adding the identity commitment (credentials or no credentials tree)
    uint256 newIdentityTreeRoot;
    /// New grade commitment to add to the grade tree.
    uint256 gradeCommitment;
    /// New root of the grade tree result of adding the grade commitment.
    uint256 newGradeTreeRoot;
    /// Zero-knowledge proof to the Test circuit.
    uint256[8] testProof;
    /// Whether the test was passed or not
    bool testPassed;
}

/// Defines the parameters that make up a Semaphore proof of inclusion.
struct CredentialClaimFullProof {
    /// Merkle root of the required credential Merkle tree.
    uint256 requiredCredentialMerkleTreeRoot;
    /// Semaphore proof nullifier hash.
    uint256 nullifierHash;
    /// Semaphore zero-knowledge proof.
    uint256[8] semaphoreProof;
}

/// Defines the parameters that make up a grade claim proof.
struct GradeClaimFullProof {
    /// Merkle root of the grade commitment Merkle tree.
    uint256 gradeClaimMerkleTreeRoot;
    /// Grade claim proof nullifier hash.
    uint256 nullifierHash;
    /// Grade claim zero-knowledge proof.
    uint256[8] gradeClaimProof;
}

/// Defines the parameters that make up a solution proof to a credential test, plus an inclusion proof
/// inside the required credential group.
struct CredentialRestrictedTestFullProof {
    /// The corresponding Semaphore full proof.
    CredentialClaimFullProof credentialClaimFullProof;
    /// The corresponding test full proof.
    TestFullProof testFullProof;
}

/// Defines the parameters that make up a solution proof to a credential test, plus a grade claim proof
/// inside the corresponding grade group.
struct GradeRestrictedTestFullProof {
    /// The corresponding grade claim proof.
    GradeClaimFullProof gradeClaimFullProof;
    /// The corresponding test full proof.
    TestFullProof testFullProof;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./base/TestCredentialManagerBase.sol";
import { PoseidonT3, PoseidonT4 } from "../libs/Poseidon.sol";
import { 
    TestCredential, 
    TestCredentialHashes,
    CredentialData,
    TestFullProof, 
    CredentialClaimFullProof,
    GradeClaimFullProof,
    CredentialRestrictedTestFullProof, 
    GradeRestrictedTestFullProof 
} from "./libs/Structs.sol";

/// @title TestCredentialManager
/// @dev Defines the behavior of the Test credential, where users gain their credentials by providing proofs of knowledge
/// of the solution to mixed tests (multiple choice + open answer components).
contract TestCredentialManager is TestCredentialManagerBase {
    /// @dev Initializes the TestCredentialManager smart contract
    /// @param credentialsRegistryAddress: Contract address of the CredentialsRegistry smart contract that
    /// governs this CredentialManager.
    /// @param testVerifierAddress: Contract address for the test circuit proof verifier.
    constructor(
        address credentialsRegistryAddress,
        address testVerifierAddress
    ) {
        credentialsRegistry = ICredentialsRegistry(credentialsRegistryAddress);
        testVerifier = ITestVerifier(testVerifierAddress);
    }

    /// @dev See {ICredentialManager-createCredential}.
    function createCredential(
        uint256 credentialId,
        uint256 treeDepth,
        bytes calldata credentialData
    ) external virtual override onlyCredentialsRegistry(credentialId) returns (CredentialState memory) {
        if (treeDepth != 16) {
            revert MerkleTreeDepthIsNotSupported();
        }

        TestCredential memory testCredential = abi.decode(credentialData, (TestCredential));

        _validateTestCredential(credentialId, testCredential);
        
        uint256 testParameters = PoseidonT4.poseidon(
            [
                uint256(testCredential.minimumGrade), 
                uint256(testCredential.multipleChoiceWeight), 
                uint256(testCredential.nQuestions)
            ]
        );
        uint256 nonPassingTestParameters;

        if (testCredential.minimumGrade != 0) {
            nonPassingTestParameters = PoseidonT4.poseidon(
                [uint256(0), uint256(testCredential.multipleChoiceWeight), uint256(testCredential.nQuestions)]
            );
        } else {
            nonPassingTestParameters = testParameters;
        }
        
        uint256 testRoot = 
            PoseidonT3.poseidon([testCredential.multipleChoiceRoot, testCredential.openAnswersHashesRoot]);

        testCredentials[credentialId] = testCredential;

        testCredentialsHashes[credentialId] = TestCredentialHashes(
            testRoot,
            testParameters,
            nonPassingTestParameters
        );

        uint256 zeroValue = uint256(keccak256(abi.encodePacked(credentialId))) >> 8;
        
        for (uint8 i = 0; i < treeDepth; ) {
            zeroValue = PoseidonT3.poseidon([zeroValue, zeroValue]);

            unchecked {
                ++i;
            }
        }

        return CredentialState(
            0,
            0,
            0,
            zeroValue,
            zeroValue,
            zeroValue
        );
    }

    /// @dev See {ICredentialHandler-updateCredential}.
    function updateCredential(
        uint256 credentialId,
        CredentialState calldata credentialState,
        bytes calldata credentialUpdate
    ) 
        external virtual override 
        onlyCredentialsRegistry(credentialId) 
        onlyValidTestCredentials(credentialId) 
        returns (CredentialState memory newCredentialState) 
    {
        TestCredential memory testCredential = testCredentials[credentialId];

        if (testCredential.requiredCredentialGradeThreshold > 0) {  // Grade restricted 
            GradeRestrictedTestFullProof memory gradeRestrictedTestFullProof = abi.decode(
                credentialUpdate, 
                (GradeRestrictedTestFullProof)
            );

            uint256 signal = uint(keccak256(abi.encode(
                gradeRestrictedTestFullProof.testFullProof.identityCommitment, 
                gradeRestrictedTestFullProof.testFullProof.newIdentityTreeRoot, 
                gradeRestrictedTestFullProof.testFullProof.gradeCommitment, 
                gradeRestrictedTestFullProof.testFullProof.newGradeTreeRoot
            )));

            _verifyGradeRestriction(
                credentialId, 
                signal,
                gradeRestrictedTestFullProof.gradeClaimFullProof
            );

            newCredentialState = _solveTest(
                credentialId, 
                credentialState,
                gradeRestrictedTestFullProof.testFullProof
            );
        } else if (testCredential.requiredCredential > 0) {  // Credential restricted 
            CredentialRestrictedTestFullProof memory credentialRestrictedTestFullProof = abi.decode(
                credentialUpdate, 
                (CredentialRestrictedTestFullProof)
            );

            uint256 signal = uint(keccak256(abi.encode(
                credentialRestrictedTestFullProof.testFullProof.identityCommitment, 
                credentialRestrictedTestFullProof.testFullProof.newIdentityTreeRoot, 
                credentialRestrictedTestFullProof.testFullProof.gradeCommitment, 
                credentialRestrictedTestFullProof.testFullProof.newGradeTreeRoot
            )));

            _verifyCredentialRestriction(
                credentialId, 
                signal,
                credentialRestrictedTestFullProof.credentialClaimFullProof
            );

            newCredentialState = _solveTest(
                credentialId, 
                credentialState, 
                credentialRestrictedTestFullProof.testFullProof
            );
        } else {  // No restriction
            TestFullProof memory testFullProof = abi.decode(
                credentialUpdate, 
                (TestFullProof)
            );

            newCredentialState = _solveTest(
                credentialId, 
                credentialState, 
                testFullProof
            );
        }
    }

    /// @dev See {ICredentialHandler-getCredentialData}.
    function getCredentialData(
        uint256 credentialId
    ) external view virtual override onlyExistingTestCredentials(credentialId) returns (bytes memory) {
        return abi.encode(testCredentials[credentialId], testCredentialsHashes[credentialId]);
    }

    /// @dev See {ICredentialHandler-getCredentialAdmin}.
    function getCredentialAdmin(
        uint256 credentialId
    ) external view virtual override onlyExistingTestCredentials(credentialId) returns (address) {
        return testCredentials[credentialId].admin;
    }

    /// @dev See {ICredentialHandler-credentialIsValid}.
    function credentialIsValid(
        uint256 credentialId
    ) external view virtual override onlyExistingTestCredentials(credentialId) returns (bool) {
        return testCredentials[credentialId].minimumGrade != 255;
    }

    /// @dev See {ICredentialHandler-credentialExists}.
    function credentialExists(
        uint256 credentialId
    ) external view virtual override onlyExistingTestCredentials(credentialId) returns (bool) {
        return true;
    }

    function _solveTest(
        uint256 credentialId,
        CredentialState memory credentialState,
        TestFullProof memory testFullProof
    ) internal returns (CredentialState memory) {
        if (testCredentials[credentialId].timeLimit != 0 && block.timestamp > testCredentials[credentialId].timeLimit) {
            revert TimeLimitReached();
        }

        if (testFullProof.testPassed || testCredentials[credentialId].minimumGrade == 0) {
            
            uint[10] memory proofInput = [
                credentialState.credentialsTreeIndex,
                testFullProof.identityCommitment,
                credentialState.credentialsTreeRoot,
                testFullProof.newIdentityTreeRoot,
                credentialState.gradeTreeIndex,
                testFullProof.gradeCommitment,
                credentialState.gradeTreeRoot,
                testFullProof.newGradeTreeRoot,
                testCredentialsHashes[credentialId].testRoot,
                testCredentialsHashes[credentialId].testParameters
            ];

            testVerifier.verifyProof(testFullProof.testProof, proofInput, testCredentials[credentialId].testHeight);

            credentialState.credentialsTreeIndex++;
            credentialState.credentialsTreeRoot = testFullProof.newIdentityTreeRoot;

            emit CredentialsMemberAdded(
                credentialId,
                credentialState.credentialsTreeIndex,
                testFullProof.identityCommitment,
                testFullProof.newIdentityTreeRoot
            );
       
        } else {

            uint[10] memory proofInput = [
                credentialState.noCredentialsTreeIndex,
                testFullProof.identityCommitment,
                credentialState.noCredentialsTreeRoot,
                testFullProof.newIdentityTreeRoot,
                credentialState.gradeTreeIndex,
                testFullProof.gradeCommitment,
                credentialState.gradeTreeRoot,
                testFullProof.newGradeTreeRoot,
                testCredentialsHashes[credentialId].testRoot,
                testCredentialsHashes[credentialId].nonPassingTestParameters
            ];

            testVerifier.verifyProof(testFullProof.testProof, proofInput, testCredentials[credentialId].testHeight);

            credentialState.noCredentialsTreeIndex++;
            credentialState.noCredentialsTreeRoot = testFullProof.newIdentityTreeRoot;

            emit NoCredentialsMemberAdded(
                credentialId,
                credentialState.noCredentialsTreeIndex,
                testFullProof.identityCommitment,
                testFullProof.newIdentityTreeRoot
            );
        }

        // User is always added to the grade tree
        credentialState.gradeTreeIndex++;
        credentialState.gradeTreeRoot = testFullProof.newGradeTreeRoot;

        emit GradeMemberAdded(
            credentialId,
            credentialState.gradeTreeIndex,
            testFullProof.gradeCommitment,
            testFullProof.newGradeTreeRoot
        );
        
        return credentialState;
    }

    function _verifyCredentialRestriction(
        uint256 credentialId,
        uint256 signal,
        CredentialClaimFullProof memory credentialClaimFullProof
    ) internal {
        uint256 requiredCredentialId = testCredentials[credentialId].requiredCredential;

        // formatBytes32String("bq-credential-restricted-test")
        uint256 externalNullifier = 0x62712d63726564656e7469616c2d726573747269637465642d74657374000000;
    
        credentialsRegistry.verifyCredentialOwnershipProof(
            requiredCredentialId,
            credentialClaimFullProof.requiredCredentialMerkleTreeRoot,
            credentialClaimFullProof.nullifierHash,
            signal,
            externalNullifier,
            credentialClaimFullProof.semaphoreProof
        );
    }

    function _verifyGradeRestriction(
        uint256 credentialId,
        uint256 signal,
        GradeClaimFullProof memory gradeClaimFullProof
    ) internal {
        uint256 requiredCredentialId = testCredentials[credentialId].requiredCredential;
        uint256 requiredCredentialGradeThreshold = testCredentials[credentialId].requiredCredentialGradeThreshold;

        // formatBytes32String("bq-grade-restricted-test")
        uint256 externalNullifier = 0x62712d67726164652d726573747269637465642d746573740000000000000000;

        credentialsRegistry.verifyGradeClaimProof(
            requiredCredentialId,
            gradeClaimFullProof.gradeClaimMerkleTreeRoot,
            gradeClaimFullProof.nullifierHash,
            requiredCredentialGradeThreshold,
            signal,
            externalNullifier,
            gradeClaimFullProof.gradeClaimProof
        );
    }
}