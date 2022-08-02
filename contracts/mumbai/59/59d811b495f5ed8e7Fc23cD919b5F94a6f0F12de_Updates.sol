// SPDX-License-Identifier: BUSL-1.1
// License details specified at address returned by calling the function: license()
pragma solidity =0.8.11;

/**
 @title Manages Updates of Multiverse properties and Ownership
 @author Freeverse.io, www.freeverse.io
*/

import "../interfaces/IWriter.sol";
import "../interfaces/IStorageGetters.sol";
import "../interfaces/IInfo.sol";
import "../interfaces/IUpdates.sol";

import "../pure/Messages.sol";
import "../pure/MerkleSerialized.sol";

contract Updates is IUpdates, Messages, MerkleSerialized {
    /// @inheritdoc IUpdates
    address public _sto;

    /// @inheritdoc IUpdates
    address public _writer;

    /// @inheritdoc IUpdates
    address public _info;

    modifier onlyUniversesRelayer() {
        require(
            msg.sender == IStorageGetters(_sto).universesRelayer(),
            "Only relay of universes is authorized."
        );
        _;
    }

    modifier onlyTXRelayer() {
        require(
            msg.sender == IStorageGetters(_sto).txRelayer(),
            "Only relay of TXs is authorized."
        );
        _;
    }

    modifier onlySuperUser() {
        require(
            msg.sender == IStorageGetters(_sto).superUser(),
            "Only superUser is authorized."
        );
        _;
    }

    constructor(
        address storageAddress,
        address writer,
        address info
    ) {
        _sto = storageAddress;
        _writer = writer;
        _info = info;
    }

    /// @inheritdoc IUpdates
    function license() external view returns (string memory) {
        return IStorageGetters(_sto).license();
    }

    /**
     * @notice Sets a new Universe root
     * @param universeIdx the idx of the Universe
     * @param newRoot the new root of the Universe
     * @param prevTransRoot the previous root of the Universe
     * @param signature the signature of the authorized relayer
     * @param ipfsCid the IPFS address where data can be fetched
     */
    function setNewUniverseRoot(
        uint256 universeIdx,
        bytes32 newRoot,
        bytes32 prevTransRoot,
        bytes calldata signature,
        string calldata ipfsCid
    ) public onlyUniversesRelayer {
        require(
            !IStorageGetters(_sto).universeIsClosed(universeIdx),
            "setNewUniverseRoot: universe already closed"
        );
        require(
            prevTransRoot ==
                IStorageGetters(_sto).universeRootCurrent(universeIdx),
            "prevTransRoot does not match"
        );
        // If relayer is not authorized, check universe owner signature
        if (!IStorageGetters(_sto).universeAuthorizesRelay(universeIdx)) {
            bytes32 msgHash = prefixed(
                keccak256(abi.encode(newRoot, prevTransRoot))
            );
            require(
                IStorageGetters(_sto).universeOwner(universeIdx) ==
                    recoverAddrFromBytes(msgHash, signature),
                "universe root update signature not correct"
            );
        }
        uint256 newVerse = IWriter(_writer).addUniverseRoot(
            universeIdx,
            newRoot,
            block.timestamp
        );
        emit NewUniverseRoot(universeIdx, newRoot, newVerse, ipfsCid);
    }

    /**
     * @notice Sets a new Universe root at verse
     * @param verse the next universe Verse
     * @param universeIdx the idx of the Universe
     * @param newRoot the new root of the Universe
     * @param prevTransRoot the previous root of the Universe
     * @param signature the signature of the authorized relayer
     * @param ipfsCid the IPFS address where data can be fetched
     */
    function submitNewUniverseRoot(
        uint256 verse,
        uint256 universeIdx,
        bytes32 newRoot,
        bytes32 prevTransRoot,
        bytes calldata signature,
        string calldata ipfsCid
    ) external onlyUniversesRelayer {
        require(
            !IStorageGetters(_sto).universeIsClosed(universeIdx),
            "setNewUniverseRoot: universe already closed"
        );
        require(
            prevTransRoot ==
                IStorageGetters(_sto).universeRootCurrent(universeIdx),
            "prevTransRoot does not match"
        );
        // If relayer is not authorized, check universe owner signature
        if (!IStorageGetters(_sto).universeAuthorizesRelay(universeIdx)) {
            bytes32 msgHash = prefixed(
                keccak256(abi.encode(newRoot, prevTransRoot))
            );
            require(
                IStorageGetters(_sto).universeOwner(universeIdx) ==
                    recoverAddrFromBytes(msgHash, signature),
                "universe root update signature not correct"
            );
        }
        uint256 newVerse = IWriter(_writer).addUniverseRoot(
            universeIdx,
            newRoot,
            block.timestamp
        );
        require(verse == newVerse, "error: incorrect universe verse");
        emit NewUniverseRoot(universeIdx, newRoot, newVerse, ipfsCid);
    }

    /**
     * @notice Submission of new TXs batch
     * @param verse The verse that will open for the L2 nodes to process
     * @param txRoot The root summarizing the TX batch
     * @param nTXs The number of TXs included in the batch
     * @param ipfsCid The IPFS address where the raw data can be obtained
     */
    function submitNewTXsRoot(
        uint256 verse,
        bytes32 txRoot,
        uint256 nTXs,
        string calldata ipfsCid
    ) external onlyTXRelayer {
        require(
            IStorageGetters(_sto).txRootsCurrentVerse() + 1 == verse,
            "error: submitNewTXsRoot for an incorrect verse"
        );
        (bool isReady, uint8 actualLevel) = IInfo(_info)
            .isReadyForTXSubmission();
        require(
            isReady,
            "not ready to accept new TX submission, verse not settled"
        );
        require(
            (actualLevel == 1) || (actualLevel == 2),
            "past verse ended up settling in incorrect level"
        );
        if (nTXs == 0) {
            require(
                txRoot == bytes32(0),
                "in a verse with no TXs, the TXRoot must be null"
            );
        }
        // stores txRoot, timestamp, and (implicitly) increments verse (which equals the length of _txBatches):
        uint8 levelsPerChallenge = IStorageGetters(_sto)
            .nLevelsPerChallengeNextVerses();
        uint8 levelVeriableByBC = computeLevelVerifiableOnChain(
            nTXs,
            2**uint256(levelsPerChallenge)
        );
        uint256 txVerse = IWriter(_writer).addTXRoot(
            txRoot,
            block.timestamp,
            nTXs,
            actualLevel,
            levelVeriableByBC
        );
        if (txVerse > 1) {
            IWriter(_writer).finalize();
        }
        emit NewTXsRoot(txRoot, nTXs, levelsPerChallenge, txVerse, ipfsCid);
    }

    /// @inheritdoc IUpdates
    function submitNewOwnershipRoot(uint256 verse, bytes32 ownershipRoot)
        external
    {
        require(
            IStorageGetters(_sto).txRootsCurrentVerse() == verse,
            "error: submitNewOwnershipRoot for an incorrect verse"
        );
        require(
            isReadyForOwnershipSubmission(),
            "not ready for ownership submission: verse not settled or new TXs not submitted yet"
        );
        if (IStorageGetters(_sto).nTXsCurrent() == 0) {
            require(
                ownershipRoot == IStorageGetters(_sto).ownershipRootCurrent(),
                "in a verse with no TXs, ownership root should remain the same"
            );
        }
        uint256 ownVerse = IWriter(_writer).addOwnershipRoot(ownershipRoot);
        IWriter(_writer).addChallenge(0, msg.sender); // this guarantees that only a staker could have done this submission
        emit NewOwnershipRoot(ownershipRoot, ownVerse);
    }

    /**
     * @notice Requests that universe roots of a given universe cannot be updated further.
     * @dev Requires that the universe is not already closed
     * @param universeIdx the idx of the Universe
     * @param validUntil the time until which the query will be valid
     * @param signature The signature of the universe owner
     */
    function requestUniverseClosure(
        uint256 universeIdx,
        uint256 validUntil,
        bytes calldata signature
    ) external onlyUniversesRelayer {
        // Check that the signature is from the universe owner
        bytes32 msgHash = prefixed(
            keccak256(abi.encode("RequestClosure", universeIdx, validUntil))
        );
        require(
            IStorageGetters(_sto).universeOwner(universeIdx) ==
                recoverAddrFromBytes(msgHash, signature),
            "requestUniverseClosure: signature not correct"
        );
        require(
            validUntil > block.timestamp,
            "requestUniverseClosure: request expired"
        );
        require(
            !IStorageGetters(_sto).universeIsClosed(universeIdx),
            "requestUniverseClosure: universe already closed"
        );
        IWriter(_writer).changeUniverseClosure(universeIdx, true, false);
        emit UniverseClosure(universeIdx, true, false);
    }

    /**
     * @notice Confirms that universe roots cannot be updated further.
     * @dev Requires a previous request to exist
     * @param universeIdx the idx of the Universe
     * @param validUntil the time until which the query will be valid
     * @param signature The signature of the universe owner
     */
    function confirmUniverseClosure(
        uint256 universeIdx,
        uint256 validUntil,
        bytes calldata signature
    ) external onlyUniversesRelayer {
        // Check that the signature is from the universe owner
        bytes32 msgHash = prefixed(
            keccak256(abi.encode("ConfirmClosure", universeIdx, validUntil))
        );
        require(
            IStorageGetters(_sto).universeOwner(universeIdx) ==
                recoverAddrFromBytes(msgHash, signature),
            "requestUniverseClosure: signature not correct"
        );
        require(
            validUntil > block.timestamp,
            "requestUniverseClosure: request expired"
        );
        require(
            !IStorageGetters(_sto).universeIsClosed(universeIdx),
            "requestUniverseClosure: universe already closed"
        );
        require(
            IStorageGetters(_sto).universeIsClosureRequested(universeIdx),
            "requestUniverseClosure: universe closure must be requested before confirming"
        );
        IWriter(_writer).changeUniverseClosure(universeIdx, true, true);
        emit UniverseClosure(universeIdx, true, true);
    }

    /**
     * @notice Removes initial request of universe closure. Cannot be used if already confirmed.
     * @param universeIdx the idx of the Universe
     * @param validUntil the time until which the query will be valid
     * @param signature The signature of the universe owner
     */
    function removeUniverseClosureRequest(
        uint256 universeIdx,
        uint256 validUntil,
        bytes calldata signature
    ) external onlyUniversesRelayer {
        // Check that the signature is from the universe owner
        bytes32 msgHash = prefixed(
            keccak256(
                abi.encode("RemoveClosureRequest", universeIdx, validUntil)
            )
        );
        require(
            IStorageGetters(_sto).universeOwner(universeIdx) ==
                recoverAddrFromBytes(msgHash, signature),
            "removeUniverseClosureRequest: signature not correct"
        );
        require(
            validUntil > block.timestamp,
            "removeUniverseClosureRequest: request expired"
        );
        require(
            !IStorageGetters(_sto).universeIsClosed(universeIdx),
            "removeUniverseClosureRequest: universe already closed"
        );
        IWriter(_writer).changeUniverseClosure(universeIdx, false, false);
        emit UniverseClosure(universeIdx, false, false);
    }

    /**
     * Main getters
     */

    /// @inheritdoc IUpdates
    function isReadyForOwnershipSubmission() public view returns (bool) {
        (, uint8 actualLevel, ) = IInfo(_info).getCurrentChallengeStatus();
        return (actualLevel == 0);
    }

    /// @inheritdoc IUpdates
    function emitOwnershipIPFSAtVerse(uint256 verse, string calldata ipfsCid)
        external
        onlyTXRelayer
    {
        emit OwnershipIPFSAtVerse(verse, ipfsCid);
    }

    /// @inheritdoc IUpdates
    function computeLevelVerifiableOnChain(
        uint256 nTXs,
        uint256 nLeavesPerChallenge
    ) public pure returns (uint8 levelVeriableByBC) {
        levelVeriableByBC = 3;
        uint256 maxTXs = nLeavesPerChallenge;
        while (nTXs > maxTXs) {
            levelVeriableByBC++;
            maxTXs *= nLeavesPerChallenge;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
 @title Deserialization of Merkle Tree parameters
 @author Freeverse.io, www.freeverse.io
*/

import "./SerializeBase.sol";

contract SerializeMerkleGet is SerializeBase {
    // Merkle Proof Getters (for transition proofs, merkle proofs in general)
    function MTPos(bytes memory serialized) public pure returns (uint256 pos) {
        assembly {
            pos := mload(add(serialized, 32))
        }
    }

    function MTLeaf(bytes memory serialized)
        public
        pure
        returns (bytes32 root)
    {
        assembly {
            root := mload(add(serialized, 64))
        } // 8 + 2 * 32
    }

    function MTProof(bytes memory serialized)
        public
        pure
        returns (bytes32[] memory proof)
    {
        // total length = 32 * 2 + 32 * nEntries
        uint32 nEntries = (uint32(serialized.length) - 64) / 32;
        require(
            serialized.length == 32 * 2 + 32 * nEntries,
            "incorrect serialized length"
        );
        return bytesToBytes32ArrayWithoutHeader(serialized, 64, nEntries);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
 @title Common tool for serilization/deserialization functions
 @author Freeverse.io, www.freeverse.io
*/

contract SerializeBase {
    // For all types of txs you always start with 1 byte for tx type:
    function txGetType(bytes memory serialized)
        public
        pure
        returns (uint8 txType)
    {
        assembly {
            txType := mload(add(serialized, 1))
        }
    }

    function bytesToBytes32ArrayWithoutHeader(
        bytes memory input,
        uint256 offset,
        uint32 nEntries
    ) public pure returns (bytes32[] memory) {
        bytes32[] memory output = new bytes32[](nEntries);

        for (uint32 p = 0; p < nEntries; p++) {
            offset += 32;
            bytes32 thisEntry;
            assembly {
                thisEntry := mload(add(input, offset))
            }
            output[p] = thisEntry;
        }
        return output;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
 @title Pure library to recover address from signatures
*/

contract Messages {
    /**
     @notice retrieves the addr that signed a message
     @param msgHash the message digest
     @param sig the message signature
     @return the retrieved address
     */
    function recoverAddrFromBytes(bytes32 msgHash, bytes memory sig)
        public
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (sig.length != 65) {
            return address(0x0);
        }

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := and(mload(add(sig, 65)), 255)
        }

        if (v < 27) {
            v += 27;
        }

        if (v != 27 && v != 28) {
            return address(0);
        }
        return ecrecover(msgHash, v, r, s);
    }

    /**
     @notice retrieves the addr that signed a message
     @param msgHash the message digest
     @param v,r,s the (v,r,s) params of the signtature
     @return the retrieved address
     */
    function recoverAddr(
        bytes32 msgHash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (address) {
        return ecrecover(msgHash, v, r, s);
    }

    /**
     @notice Returns the hash after prepending eth_sign prefix
     @param hash the hash before prepending
     @return the hash after prepending eth_sign prefix
     */
    function prefixed(bytes32 hash) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
 @title Base functions for Standard Merkle Trees
*/

contract MerkleTreeBase {
    bytes32 constant NULL_BYTES32 = bytes32(0);

    function hash_node(bytes32 left, bytes32 right)
        public
        pure
        returns (bytes32 hash)
    {
        if ((right == NULL_BYTES32) && (left == NULL_BYTES32))
            return NULL_BYTES32;
        assembly {
            mstore(0x00, left)
            mstore(0x20, right)
            hash := keccak256(0x00, 0x40)
        }
        return hash;
    }

    function buildProof(
        uint256 leafPos,
        bytes32[] memory leaves,
        uint256 nLevels
    ) public pure returns (bytes32[] memory proof) {
        if (nLevels == 0) {
            require(
                leaves.length == 1,
                "buildProof: leaves length must be 0 if nLevels = 0"
            );
            require(
                leafPos == 0,
                "buildProof: leafPos must be 0 if there is only one leaf"
            );
            return proof; // returns the empty array []
        }
        uint256 nLeaves = 2**nLevels;
        require(
            leaves.length == nLeaves,
            "number of leaves is not = pow(2,nLevels)"
        );
        proof = new bytes32[](nLevels);
        // The 1st element is just its pair
        proof[0] = ((leafPos % 2) == 0)
            ? leaves[leafPos + 1]
            : leaves[leafPos - 1];
        // The rest requires computing all hashes
        for (uint8 level = 0; level < nLevels - 1; level++) {
            nLeaves /= 2;
            leafPos /= 2;
            for (uint256 pos = 0; pos < nLeaves; pos++) {
                leaves[pos] = hash_node(leaves[2 * pos], leaves[2 * pos + 1]);
            }
            proof[level + 1] = ((leafPos % 2) == 0)
                ? leaves[leafPos + 1]
                : leaves[leafPos - 1];
        }
    }

    /**
    * @dev 
        if nLevel = 0, there is one single leaf, corresponds to an empty proof
        if nLevels = 1, we need 1 element in the proof array
        if nLevels = 2, we need 2 elements...
            .
            ..   ..
        .. .. .. ..
        01 23 45 67
    */
    function MTVerify(
        bytes32 root,
        bytes32[] memory proof,
        bytes32 leafHash,
        uint256 leafPos
    ) public pure returns (bool) {
        for (uint32 pos = 0; pos < proof.length; pos++) {
            if ((leafPos % 2) == 0) {
                leafHash = hash_node(leafHash, proof[pos]);
            } else {
                leafHash = hash_node(proof[pos], leafHash);
            }
            leafPos /= 2;
        }
        return root == leafHash;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
 @title Merkle Tree Verify for serialized inputs
 @dev Unpacks serialized inputs and then calls Merkle Tree Verify
*/

import "../pure/Merkle.sol";
import "../pure/serialization/SerializeMerkleGet.sol";

contract MerkleSerialized is Merkle, SerializeMerkleGet {
    /**
    @dev
         MTData serializes the leaf, its position, and the proof that it belongs to a tree
         MTVerifySerialized returns true if such tree has root that coincides with the provided root.
    */
    function MTVerifySerialized(bytes32 root, bytes memory MTData)
        public
        pure
        returns (bool)
    {
        return MTVerify(root, MTProof(MTData), MTLeaf(MTData), MTPos(MTData));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
 @title Computation of Root in Standard Merkle Tree
 @author Freeverse.io, www.freeverse.io
 @dev Version that does not overwrite the input leaves
*/

import "../pure/MerkleTreeBase.sol";

contract Merkle is MerkleTreeBase {
    /**
    * @dev 
        If it is called with nLeaves != 2**nLevels, then it behaves as if zero-padded to 2**nLevels
        If it is called with nLeaves != 2**nLevels, then it behaves as if zero-padded to 2**nLevels
        Assumed convention:
        nLeaves = 1, nLevels = 0, there is one leaf, which coincides with the root
        nLeaves = 2, nLevels = 1, the root is the hash of both leaves
        nLeaves = 4, nLevels = 2, ...
    */
    function merkleRoot(bytes32[] memory leaves, uint256 nLevels)
        public
        pure
        returns (bytes32)
    {
        if (nLevels == 0) return leaves[0];
        uint256 nLeaves = 2**nLevels;
        require(
            nLeaves >= leaves.length,
            "merkleRoot: not enough levels given the number of leaves"
        );

        /**
        * @dev 
            instead of reusing the leaves array entries to store hashes leaves,
            create a half-as-long array (_leaves) for that purpose, to avoid modifying
            the input array. Solidity passes-by-reference when the function is in the same contract)
            and passes-by-value when calling a function in an external contract
        */
        bytes32[] memory _leaves = new bytes32[](nLeaves);

        // level = 0 uses the original leaves:
        nLeaves /= 2;
        uint256 nLeavesNonNull = (leaves.length % 2 == 0)
            ? (leaves.length / 2)
            : ((leaves.length / 2) + 1);
        if (nLeavesNonNull > nLeaves) nLeavesNonNull = nLeaves;

        for (uint256 pos = 0; pos < nLeavesNonNull; pos++) {
            _leaves[pos] = hash_node(leaves[2 * pos], leaves[2 * pos + 1]);
        }
        for (uint256 pos = nLeavesNonNull; pos < nLeaves; pos++) {
            _leaves[pos] = NULL_BYTES32;
        }

        // levels > 0 reuse the smaller _leaves array:
        for (uint8 level = 1; level < nLevels; level++) {
            nLeaves /= 2;
            nLeavesNonNull = (nLeavesNonNull % 2 == 0)
                ? (nLeavesNonNull / 2)
                : ((nLeavesNonNull / 2) + 1);
            if (nLeavesNonNull > nLeaves) nLeavesNonNull = nLeaves;

            for (uint256 pos = 0; pos < nLeavesNonNull; pos++) {
                _leaves[pos] = hash_node(
                    _leaves[2 * pos],
                    _leaves[2 * pos + 1]
                );
            }
            for (uint256 pos = nLeavesNonNull; pos < nLeaves; pos++) {
                _leaves[pos] = NULL_BYTES32;
            }
        }
        return _leaves[0];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
 @title Interface to contract with write authorization to storage
 @author Freeverse.io, www.freeverse.io
*/

interface IWriter {
    /**
     * @notice Returns address of the license details for the contract code
     */
    function license() external view returns (string memory);

    /**
     * @notice Returns the address of the Storage contract that
     * this contract can write to
     */
    function _sto() external view returns (address);

    /**
     * @notice Returns the address of the Stakers contract that
     * this contract can communicate with
     */
    function _stakers() external view returns (address);

    /**
     * @notice Returns the address of the Updates contract that
     * this contract can communicate with
     */
    function _updates() external view returns (address);

    /**
     * @notice Returns the address of the Challenges contract that
     * this contract can communicate with
     */
    function _challenges() external view returns (address);

    // Functions that write to the Storage Contract

    /**
     * @notice Adds a new root to a Universe
     * @param universeIdx The idx of the universe
     * @param root The root to be added
     * @param timestamp The timestamp to be associated
     * @return verse The verse at which the universe is after the addition
     */
    function addUniverseRoot(
        uint256 universeIdx,
        bytes32 root,
        uint256 timestamp
    ) external returns (uint256 verse);

    /**
     * @notice Adds a new TX root
     * @dev TXs are added in batches. When adding a new batch, the ownership root settled in the previous verse
     * is settled, by copying from the challenge struct to the last ownership entry.
     * @param txRoot The nex TX root to be added
     * @param timestamp The timestamp to be associated
     * @param nTXs The number of TXs included in the batch
     * @param actualLevel The level at which the last challenge ended at
     * @param levelVeriableByBC The level at which a Challenge can be verified by the blockchain contract
     * @return txVerse The length of the TX roots array after the addition
     */
    function addTXRoot(
        bytes32 txRoot,
        uint256 timestamp,
        uint256 nTXs,
        uint8 actualLevel,
        uint8 levelVeriableByBC
    ) external returns (uint256 txVerse);

    /**
     * @notice Adds a new Ownership root
     * @dev A new ownership root, ready for challenge is received.
     * Registers timestamp of reception, creates challenge and it
     * either appends to _ownerships, or rewrites last entry, depending on
     * whether it corresponds to a new verse, or it results from a challenge
     * to the current verse.
     * The latter can happen when the challenge game moved tacitly to level 0.
     * @param ownershipRoot The new ownership root to be added
     * @return ownVerse The length of the ownership array after the addition
     */
    function addOwnershipRoot(bytes32 ownershipRoot)
        external
        returns (uint256 ownVerse);

    /**
     * @notice Pushes a challenge to the Challenges array
     * @param ownershipRoot The new proposed ownership root
     * @param transitionsRoot The transitions root provided by the challenger
     * @param rootAtEdge The edge-root stored at the provided challenge level
     * @param pos The position stored at the provided challenge level
     */
    function pushChallenge(
        bytes32 ownershipRoot,
        bytes32 transitionsRoot,
        bytes32 rootAtEdge,
        uint256 pos
    ) external;

    /**
     * @notice Sets the timestamp associated to the last ownership root received
     * @param timestamp The new time
     */
    function setLastOwnershipSubmissiontime(uint256 timestamp) external;

    /**
     * @notice Pops the last entries in the Challenge array as many times
     * as required to set its length to actualLevel
     */
    function popChallengeDataToLevel(uint8 actualLevel) external;

    /**
     * @notice Changes the data associated with the closure of a universe
     */
    function changeUniverseClosure(
        uint256 universeIdx,
        bool closureRequested,
        bool closureConfirmed
    ) external;

    /**
     * @dev Functions that write to Stakers conttact
     */

    /**
     * @notice Finalizes the currently opened challenge
     */
    function finalize() external;

    /**
     * @notice Adds a new challenge
     */
    function addChallenge(uint8 level, address staker) external;

    /**
     * @notice Resolves the last entries of a Challenge so as to
     * leave its final level to equal the provided level
     */
    function resolveToLevel(uint8 level) external;

    /**
     * @notice Pops updaters from a Challenge so as to
     * leave its final level to equal the provided level
     */
    function rewindToLevel(uint8 level) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
 @title Interface to contract that manages Updates of Multiverse properties and Ownership
 @author Freeverse.io, www.freeverse.io
*/

interface IUpdates {
    event NewUniverseRoot(
        uint256 indexed universeIdx,
        bytes32 indexed newRoot,
        uint256 indexed verse,
        string ipfsCid
    );
    event UniverseClosure(uint256 universeIdx, bool requested, bool confirmed);
    event NewTXsRoot(
        bytes32 indexed newRoot,
        uint256 nTXs,
        uint8 levelsPerChallenge,
        uint256 indexed verse,
        string ipfsCid
    );
    event NewOwnershipRoot(bytes32 indexed newRoot, uint256 indexed verse);
    event OwnershipIPFSAtVerse(uint256 indexed verse, string ipfsCid);

    /**
     * @notice Returns address of the license details for the contract code
     */
    function license() external view returns (string memory);

    /**
     * @notice Returns the address of the Storage contract that
     * this contract can communicate with
     */
    function _sto() external view returns (address);

    /**
     * @notice Returns the address of the Writer contract that
     * this contract can communicate with
     */
    function _writer() external view returns (address);

    /**
     * @notice Returns the address of the Info contract that
     * this contract can communicate with
     */
    function _info() external view returns (address);

    /**
     * @notice Submission of new Ownership state, open to challenge process until settling.
     * @dev Only stakers can submit, otherwise addChallenge would fail
     * The specified verse refers to the current verse opened by the last TXs submission
     * @param verse The tx verse of the processed TX Batch, leading to the new ownershipRoot
     * @param ownershipRoot The new ownership root
     */
    function submitNewOwnershipRoot(uint256 verse, bytes32 ownershipRoot)
        external;

    /**
     * @notice Returns true if the system is ready to accept a new ownership root
     * @dev When a TXs batch is submitted, a new Ownership state can be submitted.
     * @return Returns true if the system is ready to accept a new ownership root
     */
    function isReadyForOwnershipSubmission() external view returns (bool);

    /**
     * @notice Function to submit entire snapshots of the ownership state and inform via emission of event
     * @param verse The TX verse that the event refers to
     * @param ipfsCid The IPFS address of the data describing the event
     */
    function emitOwnershipIPFSAtVerse(uint256 verse, string calldata ipfsCid)
        external;

    /**
     * @notice Computes the level at which a challenge can be resolved by the blockchain contract
     * @dev Example:
     *  level 0: nothing has been submitted
     *  level 1: just submitted successfully: submitNewOwnershipRoot(bytes32 ownershipRoot, bytes32 transitionsRoot)
     *  level 2: either verifiable, or just submitted successfully: challenge( N roots)...
     * Formula nTXsMax = nLeavesPerChallenge^(levelBC-3) * (nLeavesPerChallenge - 1);
     * @param nTXs the number of TXs in the TX batch
     * @param nLeavesPerChallenge the number of leaves that each challenge level contains
     */
    function computeLevelVerifiableOnChain(
        uint256 nTXs,
        uint256 nLeavesPerChallenge
    ) external pure returns (uint8 levelVeriableByBC);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
 @title Interface to the main storage getters
 @author Freeverse.io, www.freeverse.io
*/

interface IStorageGetters {
    /**
     * @notice Returns address of the license details for the contract code
     */
    function license() external view returns (string memory);

    // UNIVERSE GETTERS

    /**
     * @notice Returns the owner of a universe
     * @param universeIdx The idx of the universe
     * @return The address of the owner
     */
    function universeOwner(uint256 universeIdx) external view returns (address);

    /**
     * @notice Returns the name of a universe
     * @param universeIdx The idx of the universe
     * @return The name of the universe
     */
    function universeName(uint256 universeIdx)
        external
        view
        returns (string memory);

    /**
     * @notice Returns whether owner of a universe authorizes the default relayer
     * @param universeIdx The idx of the universe
     * @return Returns true if owner of a universe authorizes the default relayer
     */
    function universeAuthorizesRelay(uint256 universeIdx)
        external
        view
        returns (bool);

    /**
     * @notice Returns the current verse at which a universe is
     * @param universeIdx The idx of the universe
     * @return The verse
     */
    function universeVerse(uint256 universeIdx) external view returns (uint256);

    /**
     * @notice Returns the root of a universe at the provided verse
     * @param universeIdx The idx of the universe
     * @param verse The verse queried
     * @return The root of the universe at the provided verse
     */
    function universeRootAtVerse(uint256 universeIdx, uint256 verse)
        external
        view
        returns (bytes32);

    /**
     * @notice Returns current root of a universe
     * @param universeIdx The idx of the universe
     * @return The root of the universe at the current verse
     */
    function universeRootCurrent(uint256 universeIdx)
        external
        view
        returns (bytes32);

    /**
     * @notice Returns the number of universes created
     * @return The number of universes created
     */
    function nUniverses() external view returns (uint256);

    /**
     * @notice Returns the submission time of a universe root at the
     * provided verse
     * @param universeIdx The idx of the universe
     * @param verse The verse queried
     * @return The submission time
     */
    function universeRootSubmissionTimeAtVerse(
        uint256 universeIdx,
        uint256 verse
    ) external view returns (uint256);

    /**
     * @notice Returns the submission time of the current universe root
     * @param universeIdx The idx of the universe
     * @return The submission time
     */
    function universeRootSubmissionTimeCurrent(uint256 universeIdx)
        external
        view
        returns (uint256);

    /**
     * @notice Returns true if the universe if closed
     * @param universeIdx The idx of the universe
     * @return Returns true if it is closed
     */
    function universeIsClosed(uint256 universeIdx) external view returns (bool);

    /**
     * @notice Returns true if the universe has its closure requested
     * @param universeIdx The idx of the universe
     * @return Returns true if it has its closure requested
     */
    function universeIsClosureRequested(uint256 universeIdx)
        external
        view
        returns (bool);

    // OWNERSHIP GETTERS

    /**
     * @notice Returns the amount of time allowed for challenging
     * an ownership root that is currently set as default for next verses
     * @return the amount of time allowed for challenging
     */
    function challengeWindowNextVerses() external view returns (uint256);

    /**
     * @notice Returns the number of levels contained in each challenge
     * set as default for next verses
     * @return the number of levels contained in each challenge
     */
    function nLevelsPerChallengeNextVerses() external view returns (uint8);

    /**
     * @notice Returns the maximum time since the production of the last
     * verse beyond which assets can be exported without new verses being produced
     * @return the maximum time
     */
    function maxTimeWithoutVerseProduction() external view returns (uint256);

    /**
     * @notice Returns information about possible export requests about the provided asset
     * @param assetId The id of the asset
     * @return owner The owner that requested the asset export
     * @return requestVerse The TX verse at which the export request was received
     * @return completedVerse The TX verse at which the export process was completed (0 if not completed)
     */
    function exportRequestInfo(uint256 assetId)
        external
        view
        returns (
            address owner,
            uint256 requestVerse,
            uint256 completedVerse
        );

    /**
     * @notice Returns the owner that requested the asset export
     * @param assetId The id of the asset
     * @return owner The owner that requested the asset export
     */
    function exportOwner(uint256 assetId) external view returns (address owner);

    /**
     * @notice Returns the TX verse at which the export request was received
     * @param assetId The id of the asset
     * @return requestVerse The TX verse at which the export request was received
     */
    function exportRequestVerse(uint256 assetId)
        external
        view
        returns (uint256 requestVerse);

    /**
     * @notice Returns the TX verse at which the export process was completed (0 if not completed)
     * @param assetId The id of the asset
     * @return completedVerse The TX verse at which the export process was completed (0 if not completed)
     */
    function exportCompletedVerse(uint256 assetId)
        external
        view
        returns (uint256 completedVerse);

    /**
     * @notice Returns the length of the ownership root array
     * @return the length of the ownership root array
     */
    function ownershipCurrentVerse() external view returns (uint256);

    /**
     * @notice Returns the length of the TXs root array
     * @return the length of the TXs root array
     */
    function txRootsCurrentVerse() external view returns (uint256);

    /**
     * @notice Returns the reference verse used in the computation of
     * the time planned for the submission of a TX batch for a given verse
     * @return The reference verse
     */
    function referenceVerse() external view returns (uint256);

    /**
     * @notice Returns the timestamp at which the reference verse took
     * place used, in the computation of the time planned for
     * the submission of a TX batch for a given verse
     * @return The timestamp at which the reference verse took place
     */
    function referenceTime() external view returns (uint256);

    /**
     * @notice Returns the seconds between txVerses between TX batch
     * submissions, used in the computation of the time planned for
     * each submission
     * @return The seconds between txVerses
     */
    function verseInterval() external view returns (uint256);

    /**
     * @notice Returns the ownership root at the provided verse
     * @param verse The verse queried
     * @return The ownership root at the provided verse
     */
    function ownershipRootAtVerse(uint256 verse)
        external
        view
        returns (bytes32);

    /**
     * @notice Returns the TX root at the provided verse
     * @param verse The verse queried
     * @return The TX root at the provided verse
     */
    function txRootAtVerse(uint256 verse) external view returns (bytes32);

    /**
     * @notice Returns the number of levels contained in each challenge
     * at the provided verse
     * @param verse The verse queried
     * @return The TX root at the provided verse
     */
    function nLevelsPerChallengeAtVerse(uint256 verse)
        external
        view
        returns (uint8);

    /**
     * @notice Returns the challenge level verifiable on chain
     * at the provided verse
     * @param verse The verse queried
     * @return The level verifiable on chain
     */
    function levelVerifiableOnChainAtVerse(uint256 verse)
        external
        view
        returns (uint8);

    /**
     * @notice Returns the number of TXs included in the batch at
     * the provided verse
     * @param verse The verse queried
     * @return The number of TXs included in the batch
     */
    function nTXsAtVerse(uint256 verse) external view returns (uint256);

    /**
     * @notice Returns the amount of time allowed for challenging
     * an ownership root at the provided verse
     * @param verse The verse queried
     * @return the amount of time allowed for challenging
     */
    function challengeWindowAtVerse(uint256 verse)
        external
        view
        returns (uint256);

    /**
     * @notice Returns the submission time of the TX batch
     * at the provided verse
     * @param verse The verse queried
     * @return the submission time of the TX batch
     */
    function txSubmissionTimeAtVerse(uint256 verse)
        external
        view
        returns (uint256);

    /**
     * @notice Returns the submission time of the Ownership root
     * at the provided verse
     * @param verse The verse queried
     * @return the submission time of the Ownership root
     */
    function ownershipSubmissionTimeAtVerse(uint256 verse)
        external
        view
        returns (uint256);

    /**
     * @notice Returns the last entry of the ownership root array
     * @return the last entry of the ownership root array
     */
    function ownershipRootCurrent() external view returns (bytes32);

    /**
     * @notice Returns the last entry of the TXs root array
     * @return the last entry of the TXs root array
     */
    function txRootCurrent() external view returns (bytes32);

    /**
     * @notice Returns the number of levels contained in each challenge
     * in the current verse
     * @return the number of levels contained in each challenge
     */
    function nLevelsPerChallengeCurrent() external view returns (uint8);

    /**
     * @notice Returns the challenge level verifiable on chain
     * in the current verse
     * @return The level verifiable on chain
     */
    function levelVerifiableOnChainCurrent() external view returns (uint8);

    /**
     * @notice Returns the number of TXs included in the batch
     * in the current verse
     * @return The number of TXs included in the batch
     */
    function nTXsCurrent() external view returns (uint256);

    /**
     * @notice Returns the amount of time allowed for challenging
     * an ownership root in the current verse
     * @return the amount of time allowed for challenging
     */
    function challengeWindowCurrent() external view returns (uint256);

    /**
     * @notice Returns the submission time of the TX batch
     * in the current verse
     * @return the submission time of the TX batch
     */
    function txSubmissionTimeCurrent() external view returns (uint256);

    /**
     * @notice Returns the submission time of the Ownership root
     * in the current verse
     * @return the submission time of the Ownership root
     */
    function ownershipSubmissionTimeCurrent() external view returns (uint256);

    // CHALLENGES GETTERS

    /**
     * @notice Returns the ownership root stored at the provided challenge level
     * @param level The queried challenge level
     * @return the stored root
     */
    function challengesOwnershipRoot(uint8 level)
        external
        view
        returns (bytes32);

    /**
     * @notice Returns the transitions root stored at the provided challenge level
     * @param level The queried challenge level
     * @return the stored root
     */
    function challengesTransitionsRoot(uint8 level)
        external
        view
        returns (bytes32);

    /**
     * @notice Returns the edge-root stored at the provided challenge level
     * @param level The queried challenge level
     * @return the stored root
     */
    function challengesRootAtEdge(uint8 level) external view returns (bytes32);

    /**
     * @notice Returns the position stored at the provided challenge level
     * @param level The queried challenge level
     * @return the position
     */
    function challengesPos(uint8 level) external view returns (uint256);

    /**
     * @notice Returns the level stored in the current challenge process
     * @return the level
     */
    function challengesLevel() external view returns (uint8);

    /**
     * @notice Returns true if all positions stored in the current
     * challenge process are zero
     * @return Returns true if all positions are zero
     */
    function areAllChallengePosZero() external view returns (bool);

    /**
     * @notice Returns number of leaves contained in each challenge
     * in the current verse
     * @return Returns true if all positions are zero
     */
    function nLeavesPerChallengeCurrent() external view returns (uint256);

    /**
     * @notice Returns the position of the leaf at the bottom level
     * of the current challenge process
     * @return bottomLevelLeafPos The position of the leaf
     */
    function computeBottomLevelLeafPos(uint256)
        external
        view
        returns (uint256 bottomLevelLeafPos);

    // ROLES GETTERS

    /**
     * @notice Returns the address with company authorization
     */
    function company() external view returns (address);

    /**
     * @notice Returns the address proposed for company authorization
     */
    function proposedCompany() external view returns (address);

    /**
     * @notice Returns the address with super user authorization
     */
    function superUser() external view returns (address);

    /**
     * @notice Returns the address with universe-roots relayer authorization
     */
    function universesRelayer() external view returns (address);

    /**
     * @notice Returns the address with TX Batch relayer authorization
     */
    function txRelayer() external view returns (address);

    /**
     * @notice Returns the address of the Stakers contract
     */
    function stakers() external view returns (address);

    /**
     * @notice Returns the address of the Writer contract
     */
    function writer() external view returns (address);

    /**
     * @notice Returns the address of the Directory contract
     */
    function directory() external view returns (address);

    /**
     * @notice Returns the address of the NFT contract where
     * assets are minted when exported
     */
    function externalNFTContract() external view returns (address);

    /**
     * @notice Returns the address of the Assets Exporter contract
     */
    function assetExporter() external view returns (address);

    // CLAIMS GETTERS

    /**
     * @notice Returns the (verse, value) pair of the provided key
     * in the provided claim
     * @param claimIdx The Idx that identifies claim
     * @param key The key queried the claim
     * @return verse The verse at which the key was set
     * @return value The value that corresponds to the key
     */
    function claim(uint256 claimIdx, uint256 key)
        external
        view
        returns (uint256 verse, string memory value);

    /**
     * @notice Returns the number of Claims created
     * @return the number of Claims created
     */
    function nClaims() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
 @title Interface to contract with info/view functions
 @author Freeverse.io, www.freeverse.io
*/

import "../interfaces/IChallengeLibStatus.sol";

interface IInfo is IChallengeLibStatus {
    /**
     * @notice Returns address of the license details for the contract code
     */
    function license() external view returns (string memory);

    /**
     * @notice Returns true only if the input owner owns the asset AND the asset has the provided props
     * @dev Proofs need to be provided. They are verified against current Ownerhsip and Universe roots.
     * @param assetId The id of the asset
     * @param owner The address of the asset owner
     * @param marketData The market data of the asset
     * @param assetCID The CID of the asset
     * @param ownershipProof The proof that the asset belongs to the current Ownership tree
     * @param propsProof The proof that the asset properties belong to the current Universe tree
     * @return whether the proofs are valid or not
     */
    function isCurrentOwnerOfAssetWithProps(
        uint256 assetId,
        address owner,
        bytes memory marketData,
        string memory assetCID,
        bytes memory ownershipProof,
        bytes memory propsProof
    ) external view returns (bool);

    /**
     * @notice Returns true only if the input owner owns the asset
     * @dev Proof needs to be provided. They are verified against current Ownership root
     * - if marketDataNeverTraded(marketData) == true (asset has never been included in the ownership tree)
     *   - it first verifies that it's not in the tree (the leafHash is bytes(0x0))
     *   - it then verifies that "owner" is the default owner
     * - if marketDataNeverTraded(marketData) == false (asset must be included in the ownership tree)
     *   - it only verifies owner == current owner stored in the ownership tree
     * Once an asset is traded once, marketDataNeverTraded remains false forever.
     * If asset has been exported, this function returns false; ownership needs to be queried in the external ERC721 contract.
     * @param assetId The id of the asset
     * @param owner The address of the asset owner
     * @param marketData The market data of the asset
     * @param proof The proof that the asset belongs to the current Ownership tree
     * @return whether the proof is valid or not
     */
    function isCurrentOwner(
        uint256 assetId,
        address owner,
        bytes memory marketData,
        bytes memory proof
    ) external view returns (bool);

    /**
     * @notice Returns true only if the input owner owned the asset at provided verse
     * @dev Identical to isCurrentOwner, but uses the Ownership root at provided verse
     * @param verse The ownership verse at which the query refers
     * @param assetId The id of the asset
     * @param owner The address of the asset owner
     * @param marketData The market data of the asset
     * @param proof The proof that the asset belonged to the Ownership tree at provided verse
     * @return whether the proof is valid or not
     */
    function wasOwnerAtVerse(
        uint256 verse,
        uint256 assetId,
        address owner,
        bytes memory marketData,
        bytes memory proof
    ) external view returns (bool);

    /**
     * @notice Serialized-inputs version of isCurrentOwner
     * @dev Unpacks inputs and calls isCurrentOwner
     * @param data The serialized ownership data
     * @return whether the proof contained in data is valid or not
     */
    function isCurrentOwnerSerialized(bytes memory data)
        external
        view
        returns (bool);

    /**
     * @notice Serialized-inputs version of wasOwnerAtVerse
     * @dev Unpacks inputs and calls wasOwnerAtVerse
     * @param verse The ownership verse at which the query refers
     * @param data The serialized ownership data
     * @return whether the proof contained in data is valid or not
     */
    function wasOwnerAtVerseSerialized(uint256 verse, bytes memory data)
        external
        view
        returns (bool);

    /**
     * @notice Returns true only if asset currently has the provided props
     * @dev Proof needs to be provided. They are verified against current Universe root
     * @param assetId The id of the asset
     * @param assetCID The CID of the asset
     * @param proof The proof that the asset belongs to the current Universe tree
     * @return whether the proof is valid or not
     */
    function isCurrentAssetProps(
        uint256 assetId,
        string memory assetCID,
        bytes memory proof
    ) external view returns (bool);

    /**
     * @notice Returns true only if the asset had the provided props at the provided verse
     * @dev Identical to isCurrentAssetProps, but uses the Universe root at the provided verse
     * @param assetId The id of the asset
     * @param verse The universe verse at which the query refers
     * @param assetCID The CID of the asset
     * @param proof The proof that the asset properties belonged to the
     * Universe tree at provided verse
     * @return whether the proof is valid or not
     */
    function wasAssetPropsAtVerse(
        uint256 assetId,
        uint256 verse,
        string memory assetCID,
        bytes memory proof
    ) external view returns (bool);

    /**
     * @notice Returns the last Ownership root that is fully settled (there could be one still in challenge process)
     * @dev There are 3 phases to consider.
     * 1. When submitTX just arrived, we just need to return the last stored ownership root
     * 2. When submitOwn just arrived, a temp root is added, so we return the last-to-last stored ownership root
     * 3. When the challenge period is over we return the settled root, which is in the challenge struct.
     * @return the current settled ownership root
     */
    function currentSettledOwnershipRoot() external view returns (bytes32);

    /**
     * @notice Returns the last settled ownership verse number
     * @return the settled ownership verse
     */
    function currentSettledOwnershipVerse() external view returns (uint256);

    /**
     * @notice Computes data about whether the system is in the phase that goes between
     * the finishing of the challenge period, and the arrival
     * of a new submission of a TX Batch
     * @return isInChallengeOver Whether the system is in the phase between the settlement of
     * the last ownership root, and the submission of a new TX Batch
     * @return actualLevel The level at which the last challenge process is, accounting for
     * implicit time-driven changes
     * @return txVerse The current txVerse
     */
    function isInChallengePeriodFinishedPhase()
        external
        view
        returns (
            bool isInChallengeOver,
            uint8 actualLevel,
            uint256 txVerse
        );

    /**
     * @notice Computes data about whether the system is ready to accept
     * the submission of a new TX batch
     * @return isReady Whether the system is ready to accept a new TX batch submission
     * @return actualLevel The level at which the last challenge process is, accounting for
     * implicit time-driven changes
     */
    function isReadyForTXSubmission()
        external
        view
        returns (bool isReady, uint8 actualLevel);

    /**
     * @notice Returns the time planned for the submission of a TX batch for a given verse
     * @param verse The TX verse queried
     * @param referenceVerse The reference verse used in the computation
     * @param referenceTime The timestamp at which the reference verse took place
     * @param verseInterval The seconds between txVerses
     * @return the time planned for the submission of a TX batch for a given verse
     */
    function plannedTime(
        uint256 verse,
        uint256 referenceVerse,
        uint256 referenceTime,
        uint256 verseInterval
    ) external pure returns (uint256);

    /**
     * @notice Returns true if the system is ready to accept challenges to the last
     * submitted ownership root
     * @return Whether the system is ready to accept challenges
     */
    function isReadyForChallenge() external view returns (bool);

    /**
     * @notice Returns data about the status of the current challenge,
     * taking into account the time passed, so that the actual level
     * can be less than the level explicitly stored, or just settled.
     * @return isSettled Whether the current challenge process is settled
     * @return actualLevel The level at which the last challenge process is, accounting for
     * @return nJumps The number of challenge levels already accounted for when
     * taking time into account
     */
    function getCurrentChallengeStatus()
        external
        view
        returns (
            bool isSettled,
            uint8 actualLevel,
            uint8 nJumps
        );

    /**
     * @notice Returns true if the asset cannot undergo any ownership change
     * because of its export process
     * @dev This function requires both the assetId and the owner as inputs,
     * because an asset is blocked only if the owner coincides with
     * the address that made the request earlier.
     * This view function gathers export info from storage and calls isAssetBlockedByExportPure
     * @param assetId the id of the asset
     * @param currentOwner the current owner of the asset
     * @return whether the asset is blocked or not
     */
    function isAssetBlockedByExport(uint256 assetId, address currentOwner)
        external
        view
        returns (bool);

    /**
     * @notice Returnss true if the asset cannot undergo any ownership change
     * @dev Pure version of isAssetBlockedByExport
     * @param currentOwner The current owner of the asset
     * @param currentVerse The current txVerse
     * @param requestOwner The address of the owner who started the export request
     * @param requestVerse The txVerse at which the export request was made
     * @param completedVerse The txVerse at which the export process was completed.
     * Should be 0 if process is not completed.
     * @return whether the asset is blocked or not
     */
    function isAssetBlockedByExportPure(
        address currentOwner,
        uint256 currentVerse,
        address requestOwner,
        uint256 requestVerse,
        uint256 completedVerse
    ) external pure returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
 @author Freeverse.io, www.freeverse.io
 @dev Interface to contract with pure function to compute the status of a challenge
*/

interface IChallengeLibStatus {
    /**
     * @dev Computes if the system is ready to accept a new TX Batch submission
     *      Data from storage is fetched previous to passing to this function.
     */
    function isInChallengePeriodFinishedPhasePure(
        uint256 nTXs,
        uint256 txRootsCurrentVerse,
        uint256 ownershipSubmissionTimeCurrent,
        uint256 challengeWindowCurrent,
        uint256 txSubmissionTimeCurrent,
        uint256 blockTimestamp,
        uint8 challengesLevel
    ) external pure returns (bool isInChallengeOver, uint8 actualLevel);

    /**
    * @dev Pure function to compute if the current challenge is settled already,
           or if due to time passing, one or more challenges have been tacitly accepted.
           In such case, the challenge processs reduces 2 levels per challenge accepted.
           inputs:
            currentTime: now, in secs, as return by block.timstamp
            lastChallTime: time at which the last challenge was received (at level 0, time of submission of ownershipRoot)
            challengeWindow: amount of time available for submitting a new challenge
            writtenLevel: the last stored level of the current challenge game
           returns:
            isSettled: if true, challenges are still accepted
            actualLevel: the level at which the challenge truly is, taking time into account.
            nJumps: the number of challenges tacitly accepted, taking time into account.
    */
    function computeChallStatus(
        uint256 nTXs,
        uint256 currentTime,
        uint256 lastTxSubmissionTime,
        uint256 lastChallTime,
        uint256 challengeWindow,
        uint8 writtenLevel
    )
        external
        pure
        returns (
            bool isSettled,
            uint8 actualLevel,
            uint8 nJumps
        );
}