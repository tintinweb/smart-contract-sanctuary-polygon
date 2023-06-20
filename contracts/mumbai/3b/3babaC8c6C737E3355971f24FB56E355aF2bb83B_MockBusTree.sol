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
 * Queue is an (ordered) list of UTXOs. All UTXOs in a queue are supposed to be
 * processed at once (i.e. as a batch of UTXOs). But queues may be processed in
 * any order (so, say, the 3rd queue may be processed before the 1st one).
 * To save gas, this contract
 * - stores the commitment to UTXOs in a queue (but not UTXOs) in the storage
 * - computes the commitment as the root of a degenerate tree (not binary one)
 * built from UTXOs (think of it as a "chain" of UTXOs).
 * For every queue, it also records the amount of rewards associated with the
 * Queue (think of "reward for processing the queue").
 * If a Queue is fully populated with UTXOs but not yet processed, the Queue is
 * considered to be "pending" processing. As a main scenario, pending Queues are
 * expected to be processed. However, partially filled Queues may be processed
 * also. So, a Queue has the following lifecycle:
 * Opened -> (optionally) Pending processing -> Processed (and deleted).
 */
abstract contract BusQueues is DegenerateIncrementalBinaryTree {
    // solhint-disable-next-line var-name-mixedcase
    uint256 private constant QUEUE_SIZE = 64;

    struct BusQueue {
        uint8 nUtxos;
        uint96 reward;
    }

    // Mapping from queue ID to queue params
    mapping(uint32 => BusQueue) internal busQueueParams;
    // Mapping from queue ID to queue commitment
    mapping(uint32 => bytes32) internal busQueueCommitments;

    // ID of the "opened" queue (next UTXO will be appended to this queue)
    uint32 private _curQueueId;
    // Number of filled non-deleted queues
    uint32 private _numPendingQueues;
    // Total rewards associated with filled non-deleted queues
    uint96 private _numPendingRewards;

    // Emitted for every UTXO appended to a queue
    event UtxoBusQueued(
        bytes32 indexed utxo,
        uint256 indexed queueId,
        uint256 utxoIndexInBatch
    );

    // Emitted when a new queue is opened (it becomes the "current" one)
    event BusQueueOpened(uint256 queueId);

    // Emitted when a queue gets its maximum size (no more UTXOs can be added,
    // the queue pends processing), or queue reward increased w/o adding UTXOs
    event BusQueuePending(uint256 indexed queueId, uint256 accumReward);

    // Emitted when a queue is registered as the processed one (and deleted)
    event BusQueueProcessed(uint256 indexed queueId);

    modifier nonEmptyBusQueue(uint32 queueId) {
        require(busQueueParams[queueId].nUtxos > 0, "BQ:EMPTY_QUEUE");
        _;
    }

    constructor() {
        // Initial value of storage variables is 0 (which is implicitly set in
        // new storage slots). There is no need for explicit initialization.
        emit BusQueueOpened(0);
    }

    function getBusQueuesStats()
        external
        view
        returns (
            uint32 curQueueId,
            uint8 curQueueNumUtxos,
            uint96 curQueueReward,
            uint32 numPendingQueues,
            uint96 numPendingRewards
        )
    {
        curQueueId = _curQueueId;
        curQueueNumUtxos = busQueueParams[curQueueId].nUtxos;
        curQueueReward = busQueueParams[curQueueId].reward;
        numPendingQueues = _numPendingQueues;
        numPendingRewards = _numPendingRewards;
    }

    function getQueue(uint32 queueId)
        public
        view
        returns (
            bytes32 commitment,
            uint8 nUtxos,
            uint96 reward
        )
    {
        commitment = busQueueCommitments[queueId];
        nUtxos = busQueueParams[queueId].nUtxos;
        reward = busQueueParams[queueId].reward;
    }

    // @dev Code that calls it MUST ensure utxos[i] < FIELD_SIZE
    function addUtxosToBusQueue(bytes32[] memory utxos, uint96 reward)
        internal
    {
        uint32 cQueueId = _curQueueId;
        BusQueue memory queue = busQueueParams[cQueueId];
        bytes32 commitment = busQueueCommitments[cQueueId];

        for (uint256 n = 0; n < utxos.length; n++) {
            bytes32 utxo = utxos[n];
            commitment = insertLeaf(utxo, commitment, queue.nUtxos == 0);
            emit UtxoBusQueued(utxo, cQueueId, queue.nUtxos);
            queue.nUtxos += 1;

            // If the current queue gets fully populated, switch to a new queue
            if (queue.nUtxos == QUEUE_SIZE) {
                // Part of the reward relates to the populated queue
                uint96 rewardUsed = uint96(
                    (uint256(reward) * (n + 1)) / utxos.length
                );
                queue.reward += rewardUsed;
                // Remaining reward is for the new queue
                reward -= rewardUsed;

                // Close the current queue
                busQueueParams[cQueueId] = queue;
                busQueueCommitments[cQueueId] = commitment;
                _numPendingQueues += 1;
                _numPendingRewards += queue.reward;
                emit BusQueuePending(cQueueId, queue.reward);

                // Open a new queue
                (cQueueId, queue) = openNewBusQueue();
                commitment = 0;
            }
        }

        if (queue.nUtxos > 0) {
            queue.reward += reward;
            busQueueParams[cQueueId] = queue;
            busQueueCommitments[cQueueId] = commitment;
        }
    }

    // It returns params of the deleted queue
    function setBusQueueAsProcessed(uint32 queueId)
        internal
        nonEmptyBusQueue(queueId)
        returns (
            bytes32 commitment,
            uint8 nUtxos,
            uint96 reward
        )
    {
        (commitment, nUtxos, reward) = getQueue(queueId);

        busQueueParams[queueId] = BusQueue(0, 0);
        busQueueCommitments[queueId] = bytes32(0);
        _numPendingQueues -= 1;
        _numPendingRewards -= reward;

        emit BusQueueProcessed(queueId);

        if (queueId == _curQueueId) openNewBusQueue();
    }

    function addBusQueueReward(uint32 queueId, uint96 extraReward)
        internal
        nonEmptyBusQueue(queueId)
    {
        require(extraReward > 0, "BQ:ZERO_REWARD");
        uint96 accumReward;
        unchecked {
            // Values are supposed to be too small to cause overflow
            accumReward = busQueueParams[queueId].reward + extraReward;
            busQueueParams[queueId].reward = accumReward;
        }
        emit BusQueuePending(queueId, accumReward);
    }

    function openNewBusQueue()
        private
        returns (uint32 newQueueId, BusQueue memory queue)
    {
        unchecked {
            // (Theoretical) overflow is acceptable
            newQueueId = _curQueueId + 1;
        }
        _curQueueId = newQueueId;
        queue = BusQueue(0, 0);
        // New storage slots contains zeros, so
        // no extra initialization for `busQueueParams[newQueueId]` needed

        emit BusQueueOpened(newQueueId);
    }
}

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-23 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.16;

import "./BusQueues.sol";
import "../../interfaces/IPantherVerifier.sol";
import { EMPTY_BUS_TREE_ROOT } from "../zeroTrees/Constants.sol";

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

    // Number of levels in every Branch, counting from roots of Batches
    uint256 private constant BRANCH_LEVELS = 10;
    // Number of Batches in a fully filled Branch
    uint256 private constant BRANCH_SIZE = 2**BRANCH_LEVELS;

    IPantherVerifier public immutable VERIFIER;
    uint160 public immutable CIRCUIT_ID;
    // solhint-enable var-name-mixedcase

    bytes32 public busTreeRoot;

    uint128 public numBatchesInBusTree;
    uint128 public numUtxosInBusTree;

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

    function onboardQueue(
        address miner,
        uint32 queueId,
        bytes32 busTreeNewRoot,
        bytes32 batchRoot,
        bytes32 busBranchNewRoot,
        SnarkProof memory proof
    ) external nonEmptyBusQueue(queueId) {
        uint128 nBatches = numBatchesInBusTree;
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

        // Verify the proof
        require(VERIFIER.verify(CIRCUIT_ID, input, proof), "BT:FAILED_PROOF");

        // Store updated Bus Tree
        busTreeRoot = busTreeNewRoot;
        uint128 leftLeafIndex = numUtxosInBusTree;
        numUtxosInBusTree = leftLeafIndex + nUtxos;
        numBatchesInBusTree = ++nBatches;

        emit BusBatchOnboarded(
            queueId,
            batchRoot,
            nUtxos,
            leftLeafIndex,
            busTreeNewRoot,
            busBranchNewRoot
        );

        if (nBatches % BRANCH_SIZE == 0) {
            // `>>BRANCH_LEVELS` is a cheaper equivalent of `/BRANCH_SIZE`
            uint256 branchIndex = (nBatches - 1) >> BRANCH_LEVELS;
            emit BusBranchFilled(branchIndex, busBranchNewRoot);
        }

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