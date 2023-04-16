//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {IWorldID} from "../interfaces/IWorldID.sol";

library LibMastaa {
    struct SponsorStorage {
        address targetContract;
        uint256 maxTxPerUser;
        mapping(address => uint256) nonce; // nonce per user, starting from 0
    }

    bytes32 constant SPONSOR_STORAGE_POSITION =
        keccak256("facets.storage.sponsor");

    function getSponsorStorage()
        internal
        pure
        returns (LibMastaa.SponsorStorage storage ms)
    {
        bytes32 position = SPONSOR_STORAGE_POSITION;
        assembly {
            ms.slot := position
        }
    }

    bytes32 constant WORLDCOIN_STORAGE_POSITION =
        keccak256("facets.storage.worldcoin");

    struct WorldCoinStorage {
        /// @dev The World ID instance that will be used for verifying proofs
        IWorldID worldId;
        /// @dev The contract's external nullifier hash
        uint256 externalNullifier;
        /// @dev Whether a nullifier hash has been used already. Used to guarantee an action is only performed once by a single person
        mapping(uint256 => bool) nullifierHashes;
        /// @dev Keep track of wallet nonce
        mapping(address => uint256) senderNonce;
    }

    function getWorldCoinStorage()
        internal
        pure
        returns (WorldCoinStorage storage ms)
    {
        bytes32 position = WORLDCOIN_STORAGE_POSITION;
        assembly {
            ms.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../../lib/LibMastaa.sol";

// Mock contract for testing (We can't use real datas because of the short time span)
contract AnalyticsPFacet {
    // TODO: add analytics functions
    function getTotalUsers() public view returns (uint256) {
        return 100;
    }
}