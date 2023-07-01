// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
// solhint-disable var-name-mixedcase
// slither-disable-next-line solc-version
pragma solidity ^0.8.4;

// Constants

uint256 constant IN_PRP_UTXOs = 1;
uint256 constant IN_UTXOs = 2 + IN_PRP_UTXOs;

uint256 constant OUT_PRP_UTXOs = 1;
uint256 constant OUT_UTXOs = 2 + OUT_PRP_UTXOs;
uint256 constant OUT_MAX_UTXOs = OUT_UTXOs;
// Number of UTXOs given as a reward for an "advanced" stake
uint256 constant OUT_RWRD_UTXOs = 2;

// For overflow protection and circuits optimization
// (must be less than the FIELD_SIZE)
uint256 constant MAX_EXT_AMOUNT = 2**96;
uint256 constant MAX_IN_CIRCUIT_AMOUNT = 2**64;
uint256 constant MAX_TIMESTAMP = 2**32;
uint256 constant MAX_ZASSET_ID = 2**160;

// Token types
// (not `enum` to let protocol extensions use bits, if needed)
uint8 constant ERC20_TOKEN_TYPE = 0x00;
uint8 constant ERC721_TOKEN_TYPE = 0x10;
uint8 constant ERC1155_TOKEN_TYPE = 0x11;
// defined for every tokenId rather than for all tokens on the contract
// (unsupported in the V0 and V1 of the MASP)
uint8 constant BY_TOKENID_TOKEN_TYPE = 0xFF;

// ZAsset statuses
// (not `enum` to let protocol extensions use bits, if needed)
uint8 constant zASSET_ENABLED = 0x01;
uint8 constant zASSET_DISABLED = 0x02;
uint8 constant zASSET_UNKNOWN = 0x00;

// UTXO data (opening values - encrypted and public) formats
uint8 constant UTXO_DATA_TYPE5 = 0x00; // for zero UTXO (no data to provide)
uint8 constant UTXO_DATA_TYPE1 = 0x01; // for UTXO w/ zero tokenId
uint8 constant UTXO_DATA_TYPE3 = 0x02; // for UTXO w/ non-zero tokenId

// Number of 32-bit words of the CiphertextMsg for UTXO_DATA_TYPE1
// (ephemeral key (packed) - 32 bytes, encrypted `random` - 32 bytes)
uint256 constant CIPHERTEXT1_WORDS = 2;

// Number of 32-bit words in the (uncompressed) spending PubKey
uint256 constant PUBKEY_WORDS = 2;
// Number of elements in `pathElements`
uint256 constant PATH_ELEMENTS_NUM = 16;

// @dev Unusable on public network address, which is useful for simulations
//  in forked test env, e.g. for bypassing SNARK proof verification like this:
// `require(isValidProof || tx.origin == DEAD_CODE_ADDRESS)`
address constant DEAD_CODE_ADDRESS = address(uint160(0xDEADC0DE));

// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
// slither-disable-next-line solc-version
pragma solidity ^0.8.4;

struct G1Point {
    uint256 x;
    uint256 y;
}

// Encoding of field elements is: X[0] * z + X[1]
struct G2Point {
    uint256[2] x;
    uint256[2] y;
}

// Verification key for SNARK
struct VerifyingKey {
    G1Point alfa1;
    G2Point beta2;
    G2Point gamma2;
    G2Point delta2;
    G1Point[] ic;
}

struct SnarkProof {
    G1Point a;
    G2Point b;
    G1Point c;
}

struct PluginData {
    address contractAddress;
    bytes callData;
}

struct ElGamalCiphertext {
    G1Point c1;
    G1Point c2;
}

// For MASP V0 and V1
struct ZAsset {
    // reserved (for networkId, tokenIdPolicy. etc..)
    uint64 _unused;
    // 0x00 by default
    uint8 version;
    // Refer to Constants.sol
    uint8 status;
    // Refer to Constants.sol
    uint8 tokenType;
    // 0x00 - no scaling
    uint8 scale;
    // token contract address
    address token;
}

struct LockData {
    // Refer to Constants.sol
    uint8 tokenType;
    // Token contract address
    address token;
    // For ERC-721, ERC-1155 tokens
    uint256 tokenId;
    // The account to transfer the token from/to (on `lock`/`unlock`)
    address extAccount;
    // The token amount to transfer to/from the Vault (on `lock`/`unlock`)
    uint96 extAmount;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// This is a stub to keep solc happy; the actual code is generated
// using poseidon_gencontract.js from circomlibjs.

library PoseidonT3 {
    function poseidon(bytes32[2] memory input) external pure returns (bytes32) {
        require(input.length == 99, "FAKE"); // always reverts
        return 0;
    }
}

library PoseidonT4 {
    function poseidon(bytes32[3] memory input) external pure returns (bytes32) {
        require(input.length == 99, "FAKE"); // always reverts
        return 0;
    }
}

library PoseidonT5 {
    function poseidon(bytes32[4] memory input) external pure returns (bytes32) {
        require(input.length == 99, "FAKE"); // always reverts
        return 0;
    }
}

library PoseidonT6 {
    function poseidon(bytes32[5] memory input) external pure returns (bytes32) {
        require(input.length == 99, "FAKE"); // always reverts
        return 0;
    }
}

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
// solhint-disable var-name-mixedcase
pragma solidity ^0.8.16;

// @dev Order of alt_bn128 and the field prime of Baby Jubjub and Poseidon hash
uint256 constant FIELD_SIZE = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

// @dev Field prime of alt_bn128
uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

// @dev Circuit extra public input as work-around for recently found groth16 vulnerability
uint256 constant MAGICAL_CONSTRAINT = 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00;

// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.16;

import { VerifyingKey } from "../../common/Types.sol";
import "./IVerifier.sol";

interface IPantherVerifier is IVerifier {
    /**
     * @notice Get the verifying key for the specified circuits
     * @param circuitId ID of the circuit
     * @dev circuitId is an address where the key is deployed as bytecode
     * @return Verifying key
     */
    function getVerifyingKey(uint160 circuitId)
        external
        view
        returns (VerifyingKey memory);
}

// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.16;

import { SnarkProof } from "../../common/Types.sol";
import "./IVerifier.sol";

interface IVerifier {
    /**
     * @notice Verify the SNARK proof
     * @param circuitId ID of the circuit (it tells which verifying key to use)
     * @param input Public input signals
     * @param proof SNARK proof
     * @return isVerified bool true if proof is valid
     */
    function verify(
        uint160 circuitId,
        uint256[] memory input,
        SnarkProof memory proof
    ) external view returns (bool isVerified);
}

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-23 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.16;

import "../merkleTrees/DegenerateIncrementalBinaryTree.sol";

/**
 * @dev It handles "queues" of commitments to UTXOs (further - "UTXOs").
 * Queue is an ordered list of UTXOs. All UTXOs in a queue are supposed to be
 * processed at once.
 * To save gas, this contract
 * - stores the commitment to UTXOs in a queue (but not UTXOs) in the storage
 * - computes the commitment as the root of a degenerate tree (not binary one)
 * built from UTXOs the queue contains.
 * For every queue, it also records the amount of rewards associated with the
 * Queue (think of "reward for processing the queue").
 * If a queue gets fully populated with UTXOs, it is considered to be "closed".
 * No more UTXOs may be appended to that queue, and a new queue is created.
 * There may be many closed which pends processing. But one only partially
 * populated queue exists (it is always the most recently created queue and it
 * is always unprocessed).
 * Queues may be processed in any order (say, the 3rd queue may go before the
 * 1st one; and a fully populated queue may be processed after the partially
 * populated one).
 * The contract maintains the doubly-linked list of unprocessed queues.
 * The queue lifecycle is:
 * "Opened -> (optionally) Closed -> Processed (and deleted)."
 */
abstract contract BusQueues is DegenerateIncrementalBinaryTree {
    // solhint-disable var-name-mixedcase
    uint256 internal constant QUEUE_MAX_LEVELS = 6;
    uint256 private constant QUEUE_MAX_SIZE = 2**QUEUE_MAX_LEVELS;
    // solhint-enable var-name-mixedcase

    /**
     * @param nUtxos Number of UTXOs in the queue
     * @param reward Rewards accumulated for the queue
     * @param firstUtxoBlock Block when the 1st UTXO was added to the queue
     * @param lastUtxoBlock Block when a UTXO was last added to the queue
     * @param prevLink Link to the previous unprocessed queue
     * @param nextLink Link to the next unprocessed queue
     * @dev If `prevLink` (`nextLink`) is 0, the unprocessed queue is the one
     * created right before (after) this queue, or no queues remain unprocessed,
     * which were created before (after) this queue. If the value is not 0, the
     * value is the unprocessed queue's ID adjusted by +1.
     */
    struct BusQueue {
        uint8 nUtxos;
        uint96 reward;
        uint40 firstUtxoBlock;
        uint40 lastUtxoBlock;
        uint32 prevLink;
        uint32 nextLink;
    }

    struct BusQueueRec {
        uint32 queueId;
        uint8 nUtxos;
        uint96 reward;
        uint40 firstUtxoBlock;
        uint40 lastUtxoBlock;
        bytes32 commitment;
    }

    // Mapping from queue ID to queue params
    mapping(uint32 => BusQueue) private _busQueues;
    // Mapping from queue ID to queue commitment
    mapping(uint32 => bytes32) private _busQueueCommitments;

    // ID of the next queue to create
    uint32 private _nextQueueId;
    // Number of unprocessed queues
    uint32 private _numPendingQueues;
    // Link to the oldest (created but yet) unprocessed queue
    // (if 0 - no such queue exists, otherwise the queue's ID adjusted by +1)
    uint32 private _oldestPendingQueueLink;

    // Emitted for every UTXO appended to a queue
    event UtxoBusQueued(
        bytes32 indexed utxo,
        uint256 indexed queueId,
        uint256 utxoIndexInBatch
    );

    // Emitted when a new queue is opened (it becomes the "current" one)
    event BusQueueOpened(uint256 queueId);

    // Emitted when queue reward increased w/o adding UTXOs
    event BusQueueRewardAdded(uint256 indexed queueId, uint256 accumReward);

    // Emitted when a queue is registered as the processed one (and deleted)
    event BusQueueProcessed(uint256 indexed queueId);

    modifier nonEmptyBusQueue(uint32 queueId) {
        require(_busQueues[queueId].nUtxos > 0, "BQ:EMPTY_QUEUE");
        _;
    }

    // Initial value of storage variables is 0, which is implicitly set in new
    // storage slots. No need for explicit initialization in the constructor.

    function getBusQueuesStats()
        external
        view
        returns (
            uint32 curQueueId,
            uint8 curQueueNumUtxos,
            uint96 curQueueReward,
            uint32 numPendingQueues,
            uint32 oldestPendingQueueLink
        )
    {
        uint32 nextQueueId = _nextQueueId;
        require(nextQueueId != 0, "BT:NO_QUEUES_YET");
        curQueueId = nextQueueId - 1;
        curQueueNumUtxos = _busQueues[curQueueId].nUtxos;
        curQueueReward = _busQueues[curQueueId].reward;
        numPendingQueues = _numPendingQueues;
        oldestPendingQueueLink = _oldestPendingQueueLink;
    }

    function getBusQueue(uint32 queueId)
        external
        view
        returns (bytes32 commitment, BusQueue memory params)
    {
        params = _busQueues[queueId];
        require(
            queueId + 1 == _nextQueueId || params.nUtxos > 0,
            "BT:UNKNOWN_OR_PROCESSED_QUEUE"
        );
        commitment = _busQueueCommitments[queueId];
    }

    // Returns upto maxLength unprocessed queues records
    function getOldestPendingQueues(uint32 maxLength)
        external
        view
        returns (BusQueueRec[] memory queues)
    {
        uint256 nQueues = _numPendingQueues;
        if (nQueues > maxLength) nQueues = maxLength;
        queues = new BusQueueRec[](nQueues);

        uint32 nextLink = _oldestPendingQueueLink;
        for (uint256 i = 0; i < nQueues; i++) {
            uint32 queueId = nextLink - 1;
            BusQueue memory queue = _busQueues[queueId];
            queues[i].queueId = queueId;
            queues[i].nUtxos = queue.nUtxos;
            queues[i].reward = queue.reward;
            queues[i].firstUtxoBlock = queue.firstUtxoBlock;
            queues[i].lastUtxoBlock = queue.lastUtxoBlock;
            queues[i].commitment = _busQueueCommitments[queueId];

            nextLink = queue.nextLink == 0 ? nextLink + 1 : queue.nextLink;
        }

        return queues;
    }

    // @dev Code that calls it MUST ensure utxos[i] < FIELD_SIZE
    function addUtxosToBusQueue(bytes32[] memory utxos, uint96 reward)
        internal
    {
        require(utxos.length < QUEUE_MAX_SIZE, "BQ:TOO_MANY_UTXOS");

        uint32 queueId;
        BusQueue memory queue;
        bytes32 commitment;
        {
            uint32 nextQueueId = _nextQueueId;
            if (nextQueueId == 0) {
                // Create the 1st queue
                (queueId, queue, commitment) = _createNewBusQueue();
                _oldestPendingQueueLink = queueId + 1;
            } else {
                // Read an existing queue from the storage
                queueId = nextQueueId - 1;
                queue = _busQueues[queueId];
                commitment = _busQueueCommitments[queueId];
            }
        }

        // Block number overflow risk ignored
        uint40 curBlock = uint40(block.number);

        for (uint256 n = 0; n < utxos.length; n++) {
            if (queue.nUtxos == 0) queue.firstUtxoBlock = curBlock;

            bytes32 utxo = utxos[n];
            commitment = insertLeaf(utxo, commitment, queue.nUtxos == 0);
            emit UtxoBusQueued(utxo, queueId, queue.nUtxos);
            queue.nUtxos += 1;

            // If the current queue gets fully populated, switch to a new queue
            if (queue.nUtxos == QUEUE_MAX_SIZE) {
                // Part of the reward relates to the populated queue
                uint96 rewardUsed = uint96(
                    (uint256(reward) * (n + 1)) / utxos.length
                );
                queue.reward += rewardUsed;
                // Remaining reward is for the new queue
                reward -= rewardUsed;

                queue.lastUtxoBlock = curBlock;
                _busQueues[queueId] = queue;
                _busQueueCommitments[queueId] = commitment;

                // Create a new queue
                (queueId, queue, commitment) = _createNewBusQueue();
            }
        }

        if (queue.nUtxos > 0) {
            queue.reward += reward;
            queue.lastUtxoBlock = curBlock;
            _busQueues[queueId] = queue;
            _busQueueCommitments[queueId] = commitment;
        }
    }

    // It delete the processed queue and returns the queue params
    function setBusQueueAsProcessed(uint32 queueId)
        internal
        nonEmptyBusQueue(queueId)
        returns (
            bytes32 commitment,
            uint8 nUtxos,
            uint96 reward
        )
    {
        BusQueue memory queue = _busQueues[queueId];
        commitment = _busQueueCommitments[queueId];
        nUtxos = queue.nUtxos;
        reward = queue.reward;

        // Clear the storage for the processed queue
        _busQueues[queueId] = BusQueue(0, 0, 0, 0, 0, 0);
        _busQueueCommitments[queueId] = bytes32(0);

        _numPendingQueues -= 1;

        // If applicable, open a new queue (_nextQueueId can't be 0 here)
        uint32 curQueueId = _nextQueueId - 1;
        if (queueId == curQueueId) {
            (curQueueId, , ) = _createNewBusQueue();
        }

        // Compute and save links to previous, next, oldest unprocessed queues
        // (link, if unequal to 0, is the unprocessed queue's ID adjusted by +1)
        uint32 nextLink = queue.nextLink == 0 ? queueId + 2 : queue.nextLink;
        uint32 nextPendingQueueId = nextLink - 1;
        {
            uint32 prevLink;
            bool isOldestQueue = _oldestPendingQueueLink == queueId + 1;
            if (isOldestQueue) {
                prevLink = 0;
                _oldestPendingQueueLink = nextLink;
            } else {
                prevLink = queue.prevLink == 0 ? queueId : queue.prevLink;
                _busQueues[prevLink - 1].nextLink = nextLink;
            }
            _busQueues[nextPendingQueueId].prevLink = prevLink;
        }

        emit BusQueueProcessed(queueId);
    }

    function addBusQueueReward(uint32 queueId, uint96 extraReward)
        internal
        nonEmptyBusQueue(queueId)
    {
        require(extraReward > 0, "BQ:ZERO_REWARD");
        uint96 accumReward;
        unchecked {
            // Values are supposed to be too small to cause overflow
            accumReward = _busQueues[queueId].reward + extraReward;
            _busQueues[queueId].reward = accumReward;
        }
        emit BusQueueRewardAdded(queueId, accumReward);
    }

    function _createNewBusQueue()
        private
        returns (
            uint32 newQueueId,
            BusQueue memory queue,
            bytes32 commitment
        )
    {
        newQueueId = _nextQueueId;

        // Store updated values in "old" storage slots
        unchecked {
            // Risks of overflow ignored
            _nextQueueId = newQueueId + 1;
            _numPendingQueues += 1;
        }
        // Explicit initialization of new storage slots to zeros is unneeded
        queue = BusQueue(0, 0, 0, 0, 0, 0);
        commitment = bytes32(0);

        emit BusQueueOpened(newQueueId);
    }
}

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-23 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.16;

import "./BusQueues.sol";
import "../../interfaces/IPantherVerifier.sol";
import { EMPTY_BUS_TREE_ROOT } from "../zeroTrees/Constants.sol";
import { MAGICAL_CONSTRAINT } from "../../crypto/SnarkConstants.sol";

/**
 * @dev The Bus Tree ("Tree") is an incremental binary Merkle tree that stores
 * commitments to UTXOs (further referred to as "UTXOs").
 * Unfilled part of the Tree contains leafs with a special "zero" value - such
 * leafs are deemed to be "empty".
 * UTXOs are inserted in the Tree in batches called "Queues".
 * The contract does not compute the Tree's root on-chain. Instead, it verifies
 * the SNARK-proof, which proves correctness of insertion into the Tree.
 * For efficient proving, leafs of a Queue get re-organized into a binary fully
 * balanced Merkle tree called the "Batch". If there are less UTXOs in a Queue
 * than needed to fill the Batch, empty leafs are appended. This way, insertion
 * constitutes replacement of an inner node of the Tree with the Batch root.
 * To ease off-chain re-construction, roots of Tree's branches ("Branches") are
 * published via on-chain logs.
 */
abstract contract BusTree is BusQueues {
    // solhint-disable var-name-mixedcase

    // Number of levels in every Batch (that is a binary tree)
    uint256 internal constant BATCH_LEVELS = QUEUE_MAX_LEVELS;

    // Number of levels in every Branch, counting from roots of Batches
    uint256 private constant BRANCH_LEVELS = 10;
    // Number of Batches in a fully filled Branch
    uint256 private constant BRANCH_SIZE = 2**BRANCH_LEVELS;
    // Bitmask for cheaper modulo math
    uint256 private constant BRANCH_BITMASK = BRANCH_SIZE - 1;

    IPantherVerifier public immutable VERIFIER;
    uint160 public immutable CIRCUIT_ID;
    // solhint-enable var-name-mixedcase

    bytes32 public busTreeRoot;

    // Number of Batches in the Bus Tree
    uint32 private _numBatchesInBusTree;
    // Number of UTXOs (excluding empty leafs) in the tree
    uint32 private _numUtxosInBusTree;
    // Block when the 1st Batch inserted in the latest branch
    uint40 private _latestBranchFirstBatchBlock;
    // Block when the latest Batch inserted in the Bus Tree
    uint40 private _latestBatchBlock;

    event BusBatchOnboarded(
        uint256 indexed queueId,
        bytes32 indexed batchRoot,
        uint256 numUtxosInBatch,
        // The index of a UTXO's leaf in the Bus Tree is
        // `leftLeafIndexInBusTree + UtxoBusQueued::utxoIndexInBatch`
        uint256 leftLeafIndexInBusTree,
        bytes32 busTreeNewRoot,
        bytes32 busBranchNewRoot
    );

    event BusBranchFilled(
        uint256 indexed branchIndex,
        bytes32 busBranchFinalRoot
    );

    // @dev It is "proxy-friendly" as it does not change the storage
    constructor(address _verifier, uint160 _circuitId) {
        require(
            IPantherVerifier(_verifier).getVerifyingKey(_circuitId).ic.length >=
                1,
            "BT:INVALID_VK"
        );
        VERIFIER = IPantherVerifier(_verifier);
        CIRCUIT_ID = _circuitId;
        // Code of `function onboardQueue` let avoid explicit initialization:
        // `busTreeRoot = EMPTY_BUS_TREE_ROOT`.
        // Initial value of storage variables is 0 (which is implicitly set in
        // new storage slots). There is no need for explicit initialization.
    }

    function getBusTreeStats()
        external
        view
        returns (
            uint32 numBatchesInBusTree,
            uint32 numUtxosInBusTree,
            uint40 latestBranchFirstBatchBlock,
            uint40 latestBatchBlock
        )
    {
        numBatchesInBusTree = _numBatchesInBusTree;
        numUtxosInBusTree = _numUtxosInBusTree;
        latestBranchFirstBatchBlock = _latestBranchFirstBatchBlock;
        latestBatchBlock = _latestBatchBlock;
    }

    function onboardQueue(
        address miner,
        uint32 queueId,
        bytes32 busTreeNewRoot,
        bytes32 batchRoot,
        bytes32 busBranchNewRoot,
        SnarkProof memory proof
    ) external nonEmptyBusQueue(queueId) {
        uint32 nBatches = _numBatchesInBusTree;
        (
            bytes32 commitment,
            uint8 nUtxos,
            uint96 reward
        ) = setBusQueueAsProcessed(queueId);

        // Circuit public input signals
        uint256[] memory input = new uint256[](9);
        // `oldRoot` signal
        input[0] = nBatches == 0
            ? uint256(EMPTY_BUS_TREE_ROOT)
            : uint256(busTreeRoot);
        // `newRoot` signal
        input[1] = uint256(busTreeNewRoot);
        // `replacedNodeIndex` signal
        input[2] = nBatches;
        // `newLeafsCommitment` signal
        input[3] = uint256(commitment);
        // `nNonEmptyNewLeafs` signal
        input[4] = uint256(nUtxos);
        // `batchRoot` signal
        input[5] = uint256(batchRoot);
        // `branchRoot` signal
        input[6] = uint256(busBranchNewRoot);
        // `extraInput` signal (front-run protection)
        input[7] = uint256(uint160(miner));
        // magicalConstraint
        input[8] = MAGICAL_CONSTRAINT;

        // Verify the proof
        require(VERIFIER.verify(CIRCUIT_ID, input, proof), "BT:FAILED_PROOF");

        {
            // Overflow risk ignored
            uint40 curBlock = uint40(block.number);
            _latestBatchBlock = curBlock;

            // `& BRANCH_BITMASK` is equivalent to `% BRANCH_SIZE`
            uint256 batchBranchIndex = uint256(nBatches) & BRANCH_BITMASK;
            if (batchBranchIndex == 0) {
                _latestBranchFirstBatchBlock = curBlock;
            } else {
                if (batchBranchIndex + 1 == BRANCH_SIZE) {
                    // `>>BRANCH_LEVELS` is equivalent to `/BRANCH_SIZE`
                    uint256 branchIndex = nBatches >> BRANCH_LEVELS;
                    emit BusBranchFilled(branchIndex, busBranchNewRoot);
                }
            }
        }

        // Store updated Bus Tree params
        busTreeRoot = busTreeNewRoot;
        // Overflow impossible as nUtxos and _numBatchesInBusTree are limited
        _numBatchesInBusTree = nBatches + 1;
        _numUtxosInBusTree += nUtxos;

        // `<< BATCH_LEVELS` is equivalent to `* 2**BATCH_LEVELS`
        uint32 leftLeafIndex = nBatches << BATCH_LEVELS;

        emit BusBatchOnboarded(
            queueId,
            batchRoot,
            nUtxos,
            leftLeafIndex,
            busTreeNewRoot,
            busBranchNewRoot
        );

        rewardMiner(miner, reward);
    }

    function rewardMiner(address miner, uint256 reward) internal virtual;
}

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-23 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.16;

/**
 * @dev It computes the root of the degenerate binary merkle tree
 * - i.e. for the tree of this kind (_tree.nLeafs is 4 here):
 *     root
 *      /\
 *     /\ 3
 *    /\ 2
 *   0  1
 * If the tree has just a single leaf, it's root equals to the leaf.
 */
abstract contract DegenerateIncrementalBinaryTree {
    function insertLeaf(
        bytes32 leaf,
        bytes32 root,
        bool isFirstLeaf
    ) internal pure returns (bytes32 newRoot) {
        newRoot = isFirstLeaf ? leaf : hash(root, leaf);
    }

    function hash(bytes32 left, bytes32 right)
        internal
        pure
        virtual
        returns (bytes32);
}

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2023 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.16;

import "../busTree/BusTree.sol";
import { PoseidonT3 } from "../../crypto/Poseidon.sol";
import { FIELD_SIZE } from "../../crypto/SnarkConstants.sol";
import { DEAD_CODE_ADDRESS } from "../../../common/Constants.sol";

contract MockBusTree is BusTree {
    event MinerRewarded(address miner, uint256 reward);

    constructor(address _verifier, uint160 _circuitId)
        BusTree(_verifier, _circuitId)
    {} // solhint-disable-line no-empty-blocks

    function rewardMiner(address miner, uint256 reward) internal override {
        emit MinerRewarded(miner, reward);
    }

    function hash(bytes32 left, bytes32 right)
        internal
        pure
        override
        returns (bytes32)
    {
        require(
            uint256(left) < FIELD_SIZE && uint256(right) < FIELD_SIZE,
            "BT:TOO_LARGE_LEAF_INPUT"
        );
        return PoseidonT3.poseidon([left, right]);
    }

    function simulateAddUtxosToBusQueue(bytes32[] memory utxos, uint96 reward)
        external
    {
        addUtxosToBusQueue(utxos, reward);
    }

    function simulateAddBusQueueReward(uint32 queueId, uint96 extraReward)
        external
    {
        addBusQueueReward(queueId, extraReward);
    }

    function simulateSetBusQueueAsProcessed(uint32 queueId)
        external
        returns (
            bytes32 commitment,
            uint8 nUtxos,
            uint96 reward
        )
    {
        require(tx.origin == DEAD_CODE_ADDRESS, "Only allowed in forked env");
        return setBusQueueAsProcessed(queueId);
    }
}

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-23 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.16;

// @dev Leaf zero value (`keccak256("Pantherprotocol")%FIELD_SIZE`)
// TODO: remove duplications of ZERO_LEAF across ../../
bytes32 constant ZERO_VALUE = bytes32(
    uint256(0x0667764c376602b72ef22218e1673c2cc8546201f9a77807570b3e5de137680d)
);

// @dev Number of levels (bellow the root, but including leafs) in the BusTree
uint256 constant BUS_TREE_LEVELS = 26;

// @dev Root of the binary tree of BUS_TREE_LEVELS with leafs of ZERO_VALUE
// Computed using `../../../../lib/binaryMerkleZerosContractGenerator.ts`
bytes32 constant EMPTY_BUS_TREE_ROOT = bytes32(
    uint256(0x1bdded415724018275c7fcc2f564f64db01b5bbeb06d65700564b05c3c59c9e6)
);