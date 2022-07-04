// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import { OwnableInternal } from "@solidstate/contracts/access/ownable/OwnableInternal.sol";

import { IVerifier } from "../interfaces/IVerifier.sol";

import { Semaphore } from "./Semaphore.sol";
import { SemaphoreStorage } from "./SemaphoreStorage.sol";
import { ISemaphoreFacet } from "../interfaces/ISemaphoreFacet.sol";


/**
 * @title SemaphoreFacet 
 */
contract SemaphoreFacet is ISemaphoreFacet, Semaphore, OwnableInternal {
    using SemaphoreStorage for SemaphoreStorage.Layout;

    function setVerifiers(Verifier[] memory _verifiers) public onlyOwner {
        for (uint8 i = 0; i < _verifiers.length; i++) {
            SemaphoreStorage.layout().verifiers[
                _verifiers[i].merkleTreeDepth
            ] = IVerifier(_verifiers[i].contractAddress);
        }
    }

    /**
     * @notice return the current version of SemaphoreFacet
     */
    function semaphoreFacetVersion() external pure override returns (string memory) {
        return "0.1.0.alpha";
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IOwnableInternal } from './IOwnableInternal.sol';
import { OwnableStorage } from './OwnableStorage.sol';

abstract contract OwnableInternal is IOwnableInternal {
    using OwnableStorage for OwnableStorage.Layout;

    modifier onlyOwner() {
        require(
            msg.sender == OwnableStorage.layout().owner,
            'Ownable: sender must be owner'
        );
        _;
    }

    function _owner() internal view virtual returns (address) {
        return OwnableStorage.layout().owner;
    }

    function _transferOwnership(address account) internal virtual {
        OwnableStorage.layout().setOwner(account);
        emit OwnershipTransferred(msg.sender, account);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title verifier interface.
 */
interface IVerifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[4] memory input
    ) external view;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import {IVerifier} from "../interfaces/IVerifier.sol";
import {ISemaphore} from "./ISemaphore.sol";
import {SemaphoreInternal} from "./SemaphoreInternal.sol";
import {SemaphoreStorage} from "./SemaphoreStorage.sol";
import {SemaphoreCoreBaseStorage} from "./base/SemaphoreCoreBase/SemaphoreCoreBaseStorage.sol";

abstract contract Semaphore is ISemaphore, SemaphoreInternal {    
    /**
     * @inheritdoc ISemaphore
     */
    function verifyProof(
        uint256 groupId,
        bytes32 signal,
        uint256 nullifierHash,
        uint256 externalNullifier,
        uint256[8] calldata proof
    ) external override {
        _beforeVerifyProof(groupId, signal, nullifierHash, externalNullifier, proof);

        _verifyProof(groupId, signal, nullifierHash, externalNullifier, proof);

        emit ProofVerified(groupId, signal);

        _afterVerifyProof(groupId, signal, nullifierHash, externalNullifier, proof);
    }

    /**
     * @inheritdoc ISemaphore
     */
    function getVerifier(uint8 merkleTreeDepth) external override returns (IVerifier) {
        return _getVerifier(merkleTreeDepth);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import { IVerifier } from "../interfaces/IVerifier.sol";

library SemaphoreStorage {
    struct Layout {
        mapping(uint256 => IVerifier) verifiers;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("simplicy.contracts.storage.Semaphore");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import { ISemaphore } from "../semaphore/ISemaphore.sol";

/**
 * @title SemaphoreFacet interface
 */
interface ISemaphoreFacet is ISemaphore {
    /**
     * @notice add Verifiers contracts to the SemaphoreFacet
     * @param _verifiers array of Verifier contracts
     */
    function setVerifiers(Verifier[] memory _verifiers) external;

     /**
     * @notice return the current version of SemaphoreFacet
     */
    function semaphoreFacetVersion() external pure returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC173Internal } from '../IERC173Internal.sol';

interface IOwnableInternal is IERC173Internal {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library OwnableStorage {
    struct Layout {
        address owner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.Ownable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setOwner(Layout storage l, address owner) internal {
        l.owner = owner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial ERC173 interface needed by internal functions
 */
interface IERC173Internal {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {IVerifier} from "../interfaces/IVerifier.sol";
import {ISemaphoreInternal} from "./ISemaphoreInternal.sol";

/**
 * @title Semaphore interface
 */
interface ISemaphore is ISemaphoreInternal {
    /**
     * @notice saves the nullifier hash to avoid double signaling and emits an event
     * if the zero-knowledge proof is valid
     * @param groupId: group id of the group
     * @param signal: semaphore signal
     * @param nullifierHash: nullifier hash
     * @param externalNullifier: external nullifier
     * @param proof: Zero-knowledge proof
     */
    function verifyProof(
        uint256 groupId,
        bytes32 signal,
        uint256 nullifierHash,
        uint256 externalNullifier,
        uint256[8] calldata proof
    ) external;

    /**
     * @notice query the verifier address by merkle tree depth
     */
    function getVerifier(uint8 merkleTreeDepth) external returns (IVerifier);

}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import {IVerifier} from "../interfaces/IVerifier.sol";
import {ISemaphoreInternal} from "./ISemaphoreInternal.sol";
import {SemaphoreStorage} from "./SemaphoreStorage.sol";
import {SemaphoreCoreBaseStorage} from "./base/SemaphoreCoreBase/SemaphoreCoreBaseStorage.sol";
import {SemaphoreCoreBaseInternal} from "./base/SemaphoreCoreBase/SemaphoreCoreBaseInternal.sol";
import {IncrementalBinaryTreeStorage} from "../utils/cryptography/IncrementalBinaryTree/IncrementalBinaryTreeStorage.sol";

/**
 * @title Base SemaphoreGroups internal functions, excluding optional extensions
 */
abstract contract SemaphoreInternal is ISemaphoreInternal, SemaphoreCoreBaseInternal {
    using SemaphoreStorage for SemaphoreStorage.Layout;
    using SemaphoreCoreBaseStorage for SemaphoreCoreBaseStorage.Layout;
    using IncrementalBinaryTreeStorage for IncrementalBinaryTreeStorage.Layout;
    
    /**
     * @notice internal function: saves the nullifier hash to avoid double signaling and emits an event
     * if the zero-knowledge proof is valid
     * @param groupId: group id of the group
     * @param signal: semaphore signal
     * @param nullifierHash: nullifier hash
     * @param externalNullifier: external nullifier
     * @param proof: Zero-knowledge proof
     */

    function _verifyProof(
        uint256 groupId,
        bytes32 signal,
        uint256 nullifierHash,
        uint256 externalNullifier,
        uint256[8] calldata proof
    ) internal virtual {
        
        uint256 root = IncrementalBinaryTreeStorage.layout().trees[groupId].root;
        uint8 depth = IncrementalBinaryTreeStorage.layout().trees[groupId].depth;

        IVerifier verifier = SemaphoreStorage.layout().verifiers[depth];

        _verifyProof(signal, root, nullifierHash, externalNullifier, proof, verifier);

        // Prevent double-voting
        SemaphoreCoreBaseStorage.layout().saveNullifierHash(nullifierHash);
    }

    /**
     * @notice query the verifier address by merkle tree depth
     */
    function _getVerifier(uint8 merkleTreeDepth) internal returns (IVerifier) {
        return SemaphoreStorage.layout().verifiers[merkleTreeDepth];
    }

    /**
     * @notice hook that is called before verifyProof
     */
    function _beforeVerifyProof(
        uint256 groupId,
        bytes32 signal,
        uint256 nullifierHash,
        uint256 externalNullifier,
        uint256[8] calldata proof
    ) internal virtual {
        uint8 depth = IncrementalBinaryTreeStorage.layout().trees[groupId].depth;
        require(depth != 0, "Semaphore: group does not exist");
    }

    /**
     * @notice hook that is called after verifyProof
     */
    function _afterVerifyProof(
        uint256 groupId,
        bytes32 signal,
        uint256 nullifierHash,
        uint256 externalNullifier,
        uint256[8] calldata proof
    ) internal virtual {}
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

library SemaphoreCoreBaseStorage {
    struct Layout {
        /**
         * @notice gets a nullifier hash and returns true or false.
         * It is used to prevent double-signaling.
         */
        mapping(uint256 => bool) nullifierHashes;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("simplicy.contracts.storage.SemaphoreCoreBase");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /**
     * @notice stores the nullifier hash to prevent double-signaling
     * @param nullifierHash: Semaphore nullifier has.
     */
    function saveNullifierHash(Layout storage s, uint256 nullifierHash)
        internal
    {
        s.nullifierHashes[nullifierHash] = true;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title Partial Semaphore interface needed by internal functions
 */
interface ISemaphoreInternal {
    struct Verifier {
        address contractAddress;
        uint8 merkleTreeDepth;
    }
    
    /**
     * @notice emitted when a Semaphore proof is verified
     * @param signal: semaphore signal
     */
    event ProofVerified(uint256 indexed groupId, bytes32 signal);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import {IVerifier} from "../../../interfaces/IVerifier.sol";
import {ISemaphoreCoreBaseInternal} from "./ISemaphoreCoreBaseInternal.sol";
import {SemaphoreCoreBaseStorage} from "./SemaphoreCoreBaseStorage.sol";

/**
 * @title Base SemaphoreGroups internal functions, excluding optional extensions
 */
abstract contract SemaphoreCoreBaseInternal is ISemaphoreCoreBaseInternal {
    using SemaphoreCoreBaseStorage for SemaphoreCoreBaseStorage.Layout;    

     /**
     * @notice asserts that no nullifier already exists and if the zero-knowledge proof is valid
     * @param signal: Semaphore signal.
     * @param root: Root of the Merkle tree.
     * @param nullifierHash: Nullifier hash.
     * @param externalNullifier: External nullifier.
     * @param proof: Zero-knowledge proof.
     * @param verifier: Verifier address.
     */
    function _verifyProof(
        bytes32 signal,
        uint256 root,
        uint256 nullifierHash,
        uint256 externalNullifier,
        uint256[8] calldata proof,
        IVerifier verifier
    ) internal view {
        require(!SemaphoreCoreBaseStorage.layout().nullifierHashes[nullifierHash], "SemaphoreCore: you cannot use the same nullifier twice");

        uint256 signalHash = _hashSignal(signal);

        verifier.verifyProof(
            [proof[0], proof[1]],
            [[proof[2], proof[3]], [proof[4], proof[5]]],
            [proof[6], proof[7]],
            [root, nullifierHash, signalHash, externalNullifier]
        );
    }

    /**
     * @notice creates a keccak256 hash of the signal
     * @param signal: Semaphore signal
     * @return Hash of the signal
     */
    function _hashSignal(bytes32 signal) private pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(signal))) >> 8;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

library IncrementalBinaryTreeStorage {
    struct IncrementalTreeData {
        uint8 depth;
        uint256 root;
        uint256 numberOfLeaves;
        mapping(uint256 => uint256) zeroes;
        mapping(uint256 => uint256[2]) lastSubtrees;
    }

    struct Layout {
         mapping(uint256 => IncrementalTreeData) trees;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("simplicy.contracts.storage.IncrementalBinaryTree");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setDepth(
        Layout storage s,
        uint256 treeId,
        uint8 depth
    ) internal {
        s.trees[treeId].depth = depth;
    }

    function setRoot(
        Layout storage s,
        uint256 treeId,
        uint256 root
    ) internal {
        s.trees[treeId].root = root;
    }

    function setNumberOfLeaves(Layout storage s, uint256 treeId) internal {
        s.trees[treeId].numberOfLeaves += 1;
    }

    function setZeroes(
        Layout storage s,
        uint256 treeId,
        uint256 leafIndex,
        uint256 zeroValue
    ) internal {
        s.trees[treeId].zeroes[leafIndex] = zeroValue;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

/**
 * @title Partial SemaphoreCore interface needed by internal functions
 */
interface ISemaphoreCoreBaseInternal {
    /**
     * @notice emitted when a proof is verified correctly and a new nullifier hash is added.
     * @param nullifierHash: hash of external and identity nullifiers.
     */
     event NullifierHashAdded(uint256 nullifierHash);
}