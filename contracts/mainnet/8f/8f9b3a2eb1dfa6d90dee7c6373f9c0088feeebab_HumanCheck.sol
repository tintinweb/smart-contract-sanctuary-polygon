/**
 *Submitted for verification at polygonscan.com on 2022-07-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library ByteHasher {
    /// @dev Creates a keccak256 hash of a bytestring.
    /// @param value The bytestring to hash
    /// @return The hash of the specified value
    /// @dev `>> 8` makes sure that the result is included in our field
    function hashToField(bytes memory value) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(value))) >> 8;
    }
}

interface IWorldID {
    /// @notice Reverts if the zero-knowledge proof is invalid.
    /// @param root The of the Merkle tree
    /// @param groupId The id of the Semaphore group
    /// @param signalHash A keccak256 hash of the Semaphore signal
    /// @param nullifierHash The nullifier hash
    /// @param externalNullifierHash A keccak256 hash of the external nullifier
    /// @param proof The zero-knowledge proof
    /// @dev  Note that a double-signaling check is not included here, and should be carried by the caller.
    function verifyProof(
        uint256 root,
        uint256 groupId,
        uint256 signalHash,
        uint256 nullifierHash,
        uint256 externalNullifierHash,
        uint256[8] calldata proof
    ) external view;
}

contract HumanCheck {
    using ByteHasher for bytes;

    /// @notice Emitted when a profile is verified
    /// @param profileId The ID of the profile getting verified
    event ProfileVerified(uint256 indexed profileId);

    /// @notice Emitted when a profile is unverified
    /// @param profileId The ID of the profile no longer verified
    event ProfileUnverified(uint256 indexed profileId);

    /// @dev The World ID instance that will be used for verifying proofs
    IWorldID internal immutable worldId;

    /// @dev The World ID group ID (always `1`)
    uint256 internal immutable groupId;

    /// @dev The World ID Action ID
    uint256 internal immutable actionId;

    /// @notice Whether a profile is verified
    /// @dev This also generates an `isVerified(uint256) getter
    mapping(uint256 => bool) public isVerified;

    /// @dev Connection between nullifiers and profiles. Used to correctly unverify the past profile when re-verifying.
    mapping(uint256 => uint256) internal nullifierHashes;

    /// @param _worldId The WorldID instance that will verify the proofs
    /// @param _groupId The WorldID group that contains our users (always `1`)
    /// @param _actionId The WorldID Action ID for the proofs
    constructor(
        IWorldID _worldId,
        uint256 _groupId,
        string memory _actionId
    ) payable {
        worldId = _worldId;
        groupId = _groupId;
        actionId = abi.encodePacked(_actionId).hashToField();
    }

    /// @notice Verify a Lens profile
    /// @param profileId The Lens profile you want to verify
    /// @param root The root of the Merkle tree (returned by the JS SDK).
    /// @param nullifierHash The nullifier hash for this proof, preventing double signaling (returned by the JS widget).
    /// @param proof The zero-knowledge proof that demostrates the claimer is registered with World ID (returned by the JS widget).
    function verify(
        uint256 profileId,
        uint256 root,
        uint256 nullifierHash,
        uint256[8] calldata proof
    ) public payable {
        worldId.verifyProof(
            root,
            groupId,
            abi.encodePacked(profileId).hashToField(),
            nullifierHash,
            actionId,
            proof
        );

        if (nullifierHashes[nullifierHash] != 0) {
            uint256 prevProfileId = nullifierHashes[nullifierHash];

            isVerified[prevProfileId] = false;
            emit ProfileUnverified(prevProfileId);
        }

        isVerified[profileId] = true;
        nullifierHashes[nullifierHash] = profileId;

        emit ProfileVerified(profileId);
    }
}