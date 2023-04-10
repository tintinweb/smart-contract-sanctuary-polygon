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
import "../interfaces/ILegacyCredentialManager.sol";

abstract contract LegacyCredentialManagerBase is ILegacyCredentialManager, Context {
    uint256 constant MAX_GRADE = 100;

    /// @dev Gets a credential id and returns the credential parameters
    mapping(uint256 => address) public legacyCredentialAdmins;
    /// @dev Gets a credential id and returns the corresponding minimum grade
    mapping(uint256 => uint256) public minimumGrades;
    /// @dev Gets a credential id and returns is valid status
    mapping(uint256 => bool) public invalidatedLegacyCredentials;

    /// @dev CredentialsRegistry smart contract
    ICredentialsRegistry public credentialsRegistry;

    /// @dev Enforces that the Credentials Registry is the transaction sender.
    /// @param credentialId: Id of the credential.
    modifier onlyCredentialsRegistry(uint256 credentialId) {
        if (address(credentialsRegistry) != _msgSender()) {
            revert CallerIsNotTheCredentialsRegistry();
        }
        _;
    }

    /// @dev Enforces that the legacy credential admin is the transaction sender.
    /// @param credentialId: Id of the credential.
    modifier onlyCredentialAdmin(uint256 credentialId) {
        if (legacyCredentialAdmins[credentialId] != tx.origin) {
            revert CallerIsNotTheCredentialAdmin();
        }
        _;
    }

    /// @dev Enforces that this legacy credential exists, that is, if it is managed by the legacy credential manager.
    /// @param credentialId: Id of the credential.
    modifier onlyExistingLegacyCredentials(uint256 credentialId) {
        if (credentialsRegistry.getCredentialManager(credentialId) != address(this)) {
            revert LegacyCredentialDoesNotExist();
        }
        credentialsRegistry.credentialExists(credentialId);
        _;
    }

    /// @dev Enforces that the legacy credential was not invalidated.
    /// Note that legacy credentials that are not defined yet are also not invalidated.
    /// @param credentialId: Id of the credential.
    modifier onlyValidLegacyCredentials(uint256 credentialId) {
        if (invalidatedLegacyCredentials[credentialId]) {
            revert CredentialWasInvalidated();
        }
        _;
    }

    /// @dev See {ICredentialHandler-invalidateCredential}
    function invalidateCredential(
        uint256 credentialId
    ) 
        external override 
        onlyExistingLegacyCredentials(credentialId) 
        onlyValidLegacyCredentials(credentialId) 
        onlyCredentialsRegistry(credentialId) 
        onlyCredentialAdmin(credentialId) 
    {
        invalidatedLegacyCredentials[credentialId] = true;

        emit CredentialInvalidated(credentialId);
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == type(ICredentialManager).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../interfaces/ICredentialManager.sol";

interface ILegacyCredentialManager is ICredentialManager {
    error LegacyCredentialDoesNotExist();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./base/LegacyCredentialManagerBase.sol";

contract LegacyCredentialManager is LegacyCredentialManagerBase {
    /// @dev Initializes the LegacyCredentialManager smart contract
    /// @param credentialsRegistryAddress: Contract address of the CredentialsRegistry smart contract that
    /// governs this CredentialManager.
    constructor(
        address credentialsRegistryAddress
    ) {
        credentialsRegistry = ICredentialsRegistry(credentialsRegistryAddress);
    }

    /// @dev See {ICredentialManager-createCredential}.
    function createCredential(
        uint256 credentialId,
        uint256 /* treeDepth */,
        bytes calldata credentialData
    ) 
        external virtual override 
        onlyCredentialsRegistry(credentialId) 
        returns (CredentialState memory) 
    {
        legacyCredentialAdmins[credentialId] = tx.origin;

        // Credential Admin sets the legacy credential initial state
        (CredentialState memory initialState, uint256 minimumGrade) = abi.decode(
            credentialData, (CredentialState, uint256)
        );

        minimumGrades[credentialId] = minimumGrade;

        return initialState;
    }

    /// @dev See {ICredentialHandler-updateCredential}.
    function updateCredential(
        uint256 credentialId,
        CredentialState calldata /* credentialState */,
        bytes calldata credentialUpdate
    ) 
        external virtual override 
        onlyCredentialsRegistry(credentialId) 
        onlyValidLegacyCredentials(credentialId) 
        onlyCredentialAdmin(credentialId) 
        returns (CredentialState memory newCredentialState) 
    {
        // Credential Admin sets the legacy credential new state
        return abi.decode(credentialUpdate, (CredentialState));
    }

    /// @dev See {ICredentialHandler-getCredentialData}.
    function getCredentialData(
        uint256 credentialId
    ) external view virtual override onlyExistingLegacyCredentials(credentialId) returns (bytes memory) {
        return abi.encode(
            credentialsRegistry.getNumberOfMerkleTreeLeaves(3 * (credentialId - 1) + 1),
            credentialsRegistry.getNumberOfMerkleTreeLeaves(3 * (credentialId - 1) + 2),
            credentialsRegistry.getNumberOfMerkleTreeLeaves(3 * (credentialId - 1) + 3),
            credentialsRegistry.getMerkleTreeRoot(3 * (credentialId - 1) + 1),
            credentialsRegistry.getMerkleTreeRoot(3 * (credentialId - 1) + 2),
            credentialsRegistry.getMerkleTreeRoot(3 * (credentialId - 1) + 3),
            minimumGrades[credentialId]
        );
    }

    /// @dev See {ICredentialHandler-getCredentialAdmin}.
    function getCredentialAdmin(
        uint256 credentialId
    ) external view virtual override onlyExistingLegacyCredentials(credentialId) returns (address) {
        return legacyCredentialAdmins[credentialId];
    }

    /// @dev See {ICredentialHandler-credentialIsValid}.
    function credentialIsValid(
        uint256 credentialId
    ) external view virtual override onlyExistingLegacyCredentials(credentialId) returns (bool) {
        return !invalidatedLegacyCredentials[credentialId];
    }

    /// @dev See {ICredentialHandler-credentialExists}.
    function credentialExists(
        uint256 credentialId
    ) external view virtual override onlyExistingLegacyCredentials(credentialId) returns (bool) {
        return true;
    }
}