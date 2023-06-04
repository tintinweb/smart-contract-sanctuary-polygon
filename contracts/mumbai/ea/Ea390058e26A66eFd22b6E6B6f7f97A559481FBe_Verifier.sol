//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title WorldID Interface
/// @author Worldcoin
/// @notice The interface to the proof verification for WorldID.
interface IWorldID {
    /// @notice Verifies a WorldID zero knowledge proof.
    /// @dev Note that a double-signaling check is not included here, and should be carried by the
    ///      caller.
    /// @dev It is highly recommended that the implementation is restricted to `view` if possible.
    ///
    /// @param root The of the Merkle tree
    /// @param signalHash A keccak256 hash of the Semaphore signal
    /// @param nullifierHash The nullifier hash
    /// @param externalNullifierHash A keccak256 hash of the external nullifier
    /// @param proof The zero-knowledge proof
    ///
    /// @custom:reverts string If the `proof` is invalid.
    function verifyProof(
        uint256 root,
        uint256 groupId,
        uint256 signalHash,
        uint256 nullifierHash,
        uint256 externalNullifierHash,
        uint256[8] calldata proof
    ) external;
}

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

pragma solidity ^0.8.0;
import "./interfaces/IWorldId.sol";
import {ByteHasher} from "./lib/ByteHasher.sol";

contract Verifier {
    using ByteHasher for bytes;

    IWorldID public worldId;
    mapping(address => bool) private verified;
    uint256 internal immutable externalNullifier;

    constructor(
        address _worldId,
        string memory _appId,
        string memory _actionId
    ) {
        worldId = IWorldID(_worldId);
        externalNullifier = abi
            .encodePacked(abi.encodePacked(_appId).hashToField(), _actionId)
            .hashToField();
    }

    event AddressVerified(address indexed _address);
    event AddressRevoked(address indexed _address);

    function verifyAddress(
        address _account,
        uint256 root,
        uint256 nullifierHash,
        uint256[8] calldata proof
    ) external returns (bool) {
        require(!verified[_account], "Already verified");

        worldId.verifyProof(
            root,
            1,
            abi.encodePacked(_account).hashToField(),
            nullifierHash,
            externalNullifier,
            proof
        );

        verified[_account] = true;
        emit AddressVerified(_account);

        return true;
    }

    function isVerified(address _address) external view returns (bool) {
        return verified[_address];
    }
}