// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// ══════════════════════════════ LIBRARY IMPORTS ══════════════════════════════
import {AGENT_TREE_HEIGHT, BONDING_OPTIMISTIC_PERIOD, SYNAPSE_DOMAIN} from "../libs/Constants.sol";
import {
    IncorrectAgentIndex,
    IncorrectAgentProof,
    CallerNotDestination,
    MustBeSynapseDomain,
    SynapseDomainForbidden,
    WithdrawTipsOptimisticPeriod
} from "../libs/Errors.sol";
import {MerkleMath} from "../libs/merkle/MerkleMath.sol";
import {AgentFlag, AgentStatus} from "../libs/Structures.sol";
// ═════════════════════════════ INTERNAL IMPORTS ══════════════════════════════
import {AgentManager, IAgentManager} from "./AgentManager.sol";
import {MessagingBase} from "../base/MessagingBase.sol";
import {IAgentSecured} from "../interfaces/IAgentSecured.sol";
import {InterfaceBondingManager} from "../interfaces/InterfaceBondingManager.sol";
import {InterfaceLightManager} from "../interfaces/InterfaceLightManager.sol";
import {InterfaceOrigin} from "../interfaces/InterfaceOrigin.sol";

/// @notice LightManager keeps track of all agents on chains other than Synapse Chain.
/// Is uses the Agent Merkle Roots from the Notary-signed attestations to stay in sync with the `BondingManager`.
/// `LightManager` is responsible for the following:
/// - Accepting the Agent Merkle Roots (passing the optimistic period check) from the `Destination` contract.
/// - Using these roots to enable agents to register themselves by proving their status.
/// - Accepting Manager Message from `BondingManager` on Synapse Chain to withdraw tips.
/// - Sending Manager Messages to `BondingManager` on Synapse Chain to slash agents, when their fraud is proven.
contract LightManager is AgentManager, InterfaceLightManager {
    // ══════════════════════════════════════════════════ STORAGE ══════════════════════════════════════════════════════
    /// @inheritdoc IAgentManager
    bytes32 public agentRoot;

    // (agentRoot => (agent => status))
    mapping(bytes32 => mapping(address => AgentStatus)) private _agentMap;

    // (index => agent)
    mapping(uint256 => address) private _agents;

    // (agent => index)
    mapping(address => uint256) private _agentIndexes;

    // ═════════════════════════════════════════ CONSTRUCTOR & INITIALIZER ═════════════════════════════════════════════

    constructor(uint32 domain) MessagingBase("0.0.3", domain) {
        if (domain == SYNAPSE_DOMAIN) revert SynapseDomainForbidden();
    }

    function initialize(address origin_, address destination_, address inbox_) external initializer {
        __AgentManager_init(origin_, destination_, inbox_);
        __Ownable_init();
    }

    // ═══════════════════════════════════════════════ AGENTS LOGIC ════════════════════════════════════════════════════

    /// @inheritdoc InterfaceLightManager
    function updateAgentStatus(address agent, AgentStatus memory status, bytes32[] memory proof) external {
        address storedAgent = _agents[status.index];
        if (storedAgent != address(0) && storedAgent != agent) revert IncorrectAgentIndex();
        // Reconstruct the agent leaf: flag should be Active
        bytes32 leaf = _agentLeaf(status.flag, status.domain, agent);
        bytes32 root = agentRoot;
        // Check that proof matches the latest merkle root
        if (MerkleMath.proofRoot(status.index, leaf, proof, AGENT_TREE_HEIGHT) != root) revert IncorrectAgentProof();
        // Save index => agent in the map
        if (storedAgent == address(0)) {
            _agents[status.index] = agent;
            _agentIndexes[agent] = status.index;
        }
        // Update the agent status against this root
        _agentMap[root][agent] = status;
        emit StatusUpdated(status.flag, status.domain, agent);
        // Notify local AgentSecured contracts, if agent flag is Slashed
        if (status.flag == AgentFlag.Slashed) {
            // This will revert if the agent has been slashed earlier
            _resolveDispute(status.index, msg.sender);
        }
    }

    /// @inheritdoc InterfaceLightManager
    function setAgentRoot(bytes32 agentRoot_) external {
        // Only destination can pass AgentRoot to be set
        if (msg.sender != destination) revert CallerNotDestination();
        _setAgentRoot(agentRoot_);
    }

    // ════════════════════════════════════════════════ TIPS LOGIC ═════════════════════════════════════════════════════

    /// @inheritdoc InterfaceLightManager
    function remoteWithdrawTips(uint32 msgOrigin, uint256 proofMaturity, address recipient, uint256 amount)
        external
        returns (bytes4 magicValue)
    {
        // Only destination can pass Manager Messages
        if (msg.sender != destination) revert CallerNotDestination();
        // Only AgentManager on Synapse Chain can give instructions to withdraw tips
        if (msgOrigin != SYNAPSE_DOMAIN) revert MustBeSynapseDomain();
        // Check that merkle proof is mature enough
        // TODO: separate constant for withdrawing tips optimistic period
        if (proofMaturity < BONDING_OPTIMISTIC_PERIOD) revert WithdrawTipsOptimisticPeriod();
        InterfaceOrigin(origin).withdrawTips(recipient, amount);
        // Magic value to return is selector of the called function
        return this.remoteWithdrawTips.selector;
    }

    // ══════════════════════════════════════════════ INTERNAL LOGIC ═══════════════════════════════════════════════════

    function _afterAgentSlashed(uint32 domain, address agent, address prover) internal virtual override {
        // Send a manager message to BondingManager on SynChain
        // remoteSlashAgent(msgOrigin, proofMaturity, domain, agent, prover) with the first two security args omitted
        InterfaceOrigin(origin).sendManagerMessage({
            destination: SYNAPSE_DOMAIN,
            optimisticPeriod: BONDING_OPTIMISTIC_PERIOD,
            payload: abi.encodeWithSelector(InterfaceBondingManager.remoteSlashAgent.selector, domain, agent, prover)
        });
    }

    /// @dev Notify local AgentSecured contracts about the opened dispute.
    function _notifyDisputeOpened(uint32 guardIndex, uint32 notaryIndex) internal override {
        // Origin contract doesn't need to know about the dispute
        IAgentSecured(destination).openDispute(guardIndex, notaryIndex);
    }

    /// @dev Notify local AgentSecured contracts about the resolved dispute.
    function _notifyDisputeResolved(uint32 slashedIndex, uint32 rivalIndex) internal override {
        // Origin contract doesn't need to know about the dispute
        IAgentSecured(destination).resolveDispute(slashedIndex, rivalIndex);
    }

    /// @dev Updates the Agent Merkle Root that Light Manager is tracking.
    function _setAgentRoot(bytes32 _agentRoot) internal {
        if (agentRoot != _agentRoot) {
            agentRoot = _agentRoot;
            emit RootUpdated(_agentRoot);
        }
    }

    // ══════════════════════════════════════════════ INTERNAL VIEWS ═══════════════════════════════════════════════════

    /// @dev Returns the stored status for the agent: whether or not they have been added
    /// using latest Agent merkle Root.
    function _storedAgentStatus(address agent) internal view override returns (AgentStatus memory) {
        return _agentMap[agentRoot][agent];
    }

    /// @dev Returns agent address for the given index. Returns zero for non existing indexes, or for indexes
    /// of the agents that have not been added to Light Manager yet.
    function _getAgent(uint256 index) internal view override returns (address agent) {
        return _agents[index];
    }

    /// @dev Returns the index of the agent in the Agent Merkle Tree. Returns zero for non existing agents, or
    /// for agents that have not been added to Light Manager yet.
    function _getIndex(address agent) internal view override returns (uint256 index) {
        return _agentIndexes[agent];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Here we define common constants to enable their easier reusing later.

// ══════════════════════════════════ MERKLE ═══════════════════════════════════
/// @dev Height of the Agent Merkle Tree
uint256 constant AGENT_TREE_HEIGHT = 32;
/// @dev Height of the Origin Merkle Tree
uint256 constant ORIGIN_TREE_HEIGHT = 32;
/// @dev Height of the Snapshot Merkle Tree. Allows up to 64 leafs, e.g. up to 32 states
uint256 constant SNAPSHOT_TREE_HEIGHT = 6;
// ══════════════════════════════════ STRUCTS ══════════════════════════════════
/// @dev See Attestation.sol: (bytes32,bytes32,uint32,uint40,uint40): 32+32+4+5+5
uint256 constant ATTESTATION_LENGTH = 78;
/// @dev See GasData.sol: (uint16,uint16,uint16,uint16,uint16,uint16): 2+2+2+2+2+2
uint256 constant GAS_DATA_LENGTH = 12;
/// @dev See Receipt.sol: (uint32,uint32,bytes32,bytes32,uint8,address,address,address): 4+4+32+32+1+20+20+20
uint256 constant RECEIPT_LENGTH = 133;
/// @dev See State.sol: (bytes32,uint32,uint32,uint40,uint40,GasData): 32+4+4+5+5+len(GasData)
uint256 constant STATE_LENGTH = 50 + GAS_DATA_LENGTH;
/// @dev Maximum amount of states in a single snapshot. Each state produces two leafs in the tree
uint256 constant SNAPSHOT_MAX_STATES = 1 << (SNAPSHOT_TREE_HEIGHT - 1);
// ══════════════════════════════════ MESSAGE ══════════════════════════════════
/// @dev See Header.sol: (uint8,uint32,uint32,uint32,uint32): 1+4+4+4+4
uint256 constant HEADER_LENGTH = 17;
/// @dev See Request.sol: (uint96,uint64,uint32): 12+8+4
uint256 constant REQUEST_LENGTH = 24;
/// @dev See Tips.sol: (uint64,uint64,uint64,uint64): 8+8+8+8
uint256 constant TIPS_LENGTH = 32;
/// @dev The amount of discarded last bits when encoding tip values
uint256 constant TIPS_GRANULARITY = 32;
/// @dev Tip values could be only the multiples of TIPS_MULTIPLIER
uint256 constant TIPS_MULTIPLIER = 1 << TIPS_GRANULARITY;
// ══════════════════════════════ STATEMENT SALTS ══════════════════════════════
/// @dev Salts for signing various statements
bytes32 constant ATTESTATION_VALID_SALT = keccak256("ATTESTATION_VALID_SALT");
bytes32 constant ATTESTATION_INVALID_SALT = keccak256("ATTESTATION_INVALID_SALT");
bytes32 constant RECEIPT_VALID_SALT = keccak256("RECEIPT_VALID_SALT");
bytes32 constant RECEIPT_INVALID_SALT = keccak256("RECEIPT_INVALID_SALT");
bytes32 constant SNAPSHOT_VALID_SALT = keccak256("SNAPSHOT_VALID_SALT");
bytes32 constant STATE_INVALID_SALT = keccak256("STATE_INVALID_SALT");
// ═════════════════════════════════ PROTOCOL ══════════════════════════════════
/// @dev Optimistic period for new agent roots in LightManager
uint32 constant AGENT_ROOT_OPTIMISTIC_PERIOD = 1 days;
uint32 constant BONDING_OPTIMISTIC_PERIOD = 1 days;
/// @dev Amount of time without fresh data from Notaries before contract owner can resolve stuck disputes manually
uint256 constant FRESH_DATA_TIMEOUT = 4 hours;
/// @dev Maximum bytes per message = 2 KiB (somewhat arbitrarily set to begin)
uint256 constant MAX_CONTENT_BYTES = 2 * 2 ** 10;
/// @dev Domain of the Synapse Chain
// TODO: replace the placeholder with actual value (for MVP this is Optimism chainId)
uint32 constant SYNAPSE_DOMAIN = 10;

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// ══════════════════════════════ INVALID CALLER ═══════════════════════════════

error CallerNotAgentManager();
error CallerNotDestination();
error CallerNotInbox();
error CallerNotSummit();

// ══════════════════════════════ INCORRECT DATA ═══════════════════════════════

error IncorrectAttestation();
error IncorrectAgentDomain();
error IncorrectAgentIndex();
error IncorrectAgentProof();
error IncorrectDataHash();
error IncorrectDestinationDomain();
error IncorrectOriginDomain();
error IncorrectSnapshotProof();
error IncorrectSnapshotRoot();
error IncorrectState();
error IncorrectStatesAmount();
error IncorrectTipsProof();
error IncorrectVersionLength();

error IncorrectNonce();
error IncorrectSender();
error IncorrectRecipient();

error FlagOutOfRange();
error IndexOutOfRange();
error NonceOutOfRange();

error OutdatedNonce();

error UnformattedAttestation();
error UnformattedAttestationReport();
error UnformattedBaseMessage();
error UnformattedCallData();
error UnformattedCallDataPrefix();
error UnformattedMessage();
error UnformattedReceipt();
error UnformattedReceiptReport();
error UnformattedSignature();
error UnformattedSnapshot();
error UnformattedState();
error UnformattedStateReport();

// ═══════════════════════════════ MERKLE TREES ════════════════════════════════

error LeafNotProven();
error MerkleTreeFull();
error NotEnoughLeafs();
error TreeHeightTooLow();

// ═════════════════════════════ OPTIMISTIC PERIOD ═════════════════════════════

error BaseClientOptimisticPeriod();
error MessageOptimisticPeriod();
error SlashAgentOptimisticPeriod();
error WithdrawTipsOptimisticPeriod();
error ZeroProofMaturity();

// ═══════════════════════════════ AGENT MANAGER ═══════════════════════════════

error AgentNotGuard();
error AgentNotNotary();

error AgentCantBeAdded();
error AgentNotActive();
error AgentNotActiveNorUnstaking();
error AgentNotFraudulent();
error AgentNotUnstaking();
error AgentUnknown();

error DisputeAlreadyResolved();
error DisputeNotOpened();
error DisputeNotStuck();
error GuardInDispute();
error NotaryInDispute();

error MustBeSynapseDomain();
error SynapseDomainForbidden();

// ════════════════════════════════ DESTINATION ════════════════════════════════

error AlreadyExecuted();
error AlreadyFailed();
error DuplicatedSnapshotRoot();
error IncorrectMagicValue();
error GasLimitTooLow();
error GasSuppliedTooLow();

// ══════════════════════════════════ ORIGIN ═══════════════════════════════════

error ContentLengthTooBig();
error EthTransferFailed();
error InsufficientEthBalance();

// ════════════════════════════════ GAS ORACLE ═════════════════════════════════

error LocalGasDataNotSet();
error RemoteGasDataNotSet();

// ═══════════════════════════════════ TIPS ════════════════════════════════════

error TipsClaimMoreThanEarned();
error TipsClaimZero();
error TipsOverflow();
error TipsValueTooLow();

// ════════════════════════════════ MEMORY VIEW ════════════════════════════════

error IndexedTooMuch();
error ViewOverrun();
error OccupiedMemory();
error UnallocatedMemory();
error PrecompileOutOfGas();

// ═════════════════════════════════ MULTICALL ═════════════════════════════════

error MulticallFailed();

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {TreeHeightTooLow} from "../Errors.sol";

library MerkleMath {
    // ═════════════════════════════════════════ BASIC MERKLE CALCULATIONS ═════════════════════════════════════════════

    /**
     * @notice Calculates the merkle root for the given leaf and merkle proof.
     * @dev Will revert if proof length exceeds the tree height.
     * @param index     Index of `leaf` in tree
     * @param leaf      Leaf of the merkle tree
     * @param proof     Proof of inclusion of `leaf` in the tree
     * @param height    Height of the merkle tree
     * @return root_    Calculated Merkle Root
     */
    function proofRoot(uint256 index, bytes32 leaf, bytes32[] memory proof, uint256 height)
        internal
        pure
        returns (bytes32 root_)
    {
        // Proof length could not exceed the tree height
        uint256 proofLen = proof.length;
        if (proofLen > height) revert TreeHeightTooLow();
        root_ = leaf;
        /// @dev Apply unchecked to all ++h operations
        unchecked {
            // Go up the tree levels from the leaf following the proof
            for (uint256 h = 0; h < proofLen; ++h) {
                // Get a sibling node on current level: this is proof[h]
                root_ = getParent(root_, proof[h], index, h);
            }
            // Go up to the root: the remaining siblings are EMPTY
            for (uint256 h = proofLen; h < height; ++h) {
                root_ = getParent(root_, bytes32(0), index, h);
            }
        }
    }

    /**
     * @notice Calculates the parent of a node on the path from one of the leafs to root.
     * @param node          Node on a path from tree leaf to root
     * @param sibling       Sibling for a given node
     * @param leafIndex     Index of the tree leaf
     * @param nodeHeight    "Level height" for `node` (ZERO for leafs, ORIGIN_TREE_HEIGHT for root)
     */
    function getParent(bytes32 node, bytes32 sibling, uint256 leafIndex, uint256 nodeHeight)
        internal
        pure
        returns (bytes32 parent)
    {
        // Index for `node` on its "tree level" is (leafIndex / 2**height)
        // "Left child" has even index, "right child" has odd index
        if ((leafIndex >> nodeHeight) & 1 == 0) {
            // Left child
            return getParent(node, sibling);
        } else {
            // Right child
            return getParent(sibling, node);
        }
    }

    /// @notice Calculates the parent of tow nodes in the merkle tree.
    /// @dev We use implementation with H(0,0) = 0
    /// This makes EVERY empty node in the tree equal to ZERO,
    /// saving us from storing H(0,0), H(H(0,0), H(0, 0)), and so on
    /// @param leftChild    Left child of the calculated node
    /// @param rightChild   Right child of the calculated node
    /// @return parent      Value for the node having above mentioned children
    function getParent(bytes32 leftChild, bytes32 rightChild) internal pure returns (bytes32 parent) {
        if (leftChild == bytes32(0) && rightChild == bytes32(0)) {
            return 0;
        } else {
            return keccak256(bytes.concat(leftChild, rightChild));
        }
    }

    // ════════════════════════════════ ROOT/PROOF CALCULATION FOR A LIST OF LEAFS ═════════════════════════════════════

    /**
     * @notice Calculates merkle root for a list of given leafs.
     * Merkle Tree is constructed by padding the list with ZERO values for leafs until list length is `2**height`.
     * Merkle Root is calculated for the constructed tree, and then saved in `leafs[0]`.
     * > Note:
     * > - `leafs` values are overwritten in the process to avoid excessive memory allocations.
     * > - Caller is expected not to reuse `hashes` list after the call, and only use `leafs[0]` value,
     * which is guaranteed to contain the calculated merkle root.
     * > - root is calculated using the `H(0,0) = 0` Merkle Tree implementation. See MerkleTree.sol for details.
     * @dev Amount of leaves should be at most `2**height`
     * @param hashes    List of leafs for the merkle tree (to be overwritten)
     * @param height    Height of the Merkle Tree to construct
     */
    function calculateRoot(bytes32[] memory hashes, uint256 height) internal pure {
        uint256 levelLength = hashes.length;
        // Amount of hashes could not exceed amount of leafs in tree with the given height
        if (levelLength > (1 << height)) revert TreeHeightTooLow();
        /// @dev h, leftIndex, rightIndex and levelLength never overflow
        unchecked {
            // Iterate `height` levels up from the leaf level
            // For every level we will only record "significant values", i.e. not equal to ZERO
            for (uint256 h = 0; h < height; ++h) {
                // Let H be the height of the "current level". H = 0 for the "leafs level".
                // Invariant: a total of 2**(HEIGHT-H) nodes are on the current level
                // Invariant: hashes[0 .. length) are "significant values" for the "current level" nodes
                // Invariant: bytes32(0) is the value for nodes with indexes [length .. 2**(HEIGHT-H))

                // Iterate over every pair of (leftChild, rightChild) on the current level
                for (uint256 leftIndex = 0; leftIndex < levelLength; leftIndex += 2) {
                    uint256 rightIndex = leftIndex + 1;
                    bytes32 leftChild = hashes[leftIndex];
                    // Note: rightChild might be ZERO
                    bytes32 rightChild = rightIndex < levelLength ? hashes[rightIndex] : bytes32(0);
                    // Record the parent hash in the same array. This will not affect
                    // further calculations for the same level: (leftIndex >> 1) <= leftIndex.
                    hashes[leftIndex >> 1] = getParent(leftChild, rightChild);
                }
                // Set length for the "parent level": the amount of iterations for the for loop above.
                levelLength = (levelLength + 1) >> 1;
            }
        }
    }

    /**
     * @notice Generates a proof of inclusion of a leaf in the list. If the requested index is outside
     * of the list range, generates a proof of inclusion for an empty leaf (proof of non-inclusion).
     * The Merkle Tree is constructed by padding the list with ZERO values until list length is a power of two
     * __AND__ index is in the extended list range. For example:
     *  - `hashes.length == 6` and `0 <= index <= 7` will "extend" the list to 8 entries.
     *  - `hashes.length == 6` and `7 < index <= 15` will "extend" the list to 16 entries.
     * > Note: `leafs` values are overwritten in the process to avoid excessive memory allocations.
     * Caller is expected not to reuse `hashes` list after the call.
     * @param hashes    List of leafs for the merkle tree (to be overwritten)
     * @param index     Leaf index to generate the proof for
     * @return proof    Generated merkle proof
     */
    function calculateProof(bytes32[] memory hashes, uint256 index) internal pure returns (bytes32[] memory proof) {
        // Use only meaningful values for the shortened proof
        // Check if index is within the list range (we want to generates proofs for outside leafs as well)
        uint256 height = getHeight(index < hashes.length ? hashes.length : (index + 1));
        proof = new bytes32[](height);
        uint256 levelLength = hashes.length;
        /// @dev h, leftIndex, rightIndex and levelLength never overflow
        unchecked {
            // Iterate `height` levels up from the leaf level
            // For every level we will only record "significant values", i.e. not equal to ZERO
            for (uint256 h = 0; h < height; ++h) {
                // Use sibling for the merkle proof; `index^1` is index of our sibling
                proof[h] = (index ^ 1 < levelLength) ? hashes[index ^ 1] : bytes32(0);

                // Let H be the height of the "current level". H = 0 for the "leafs level".
                // Invariant: a total of 2**(HEIGHT-H) nodes are on the current level
                // Invariant: hashes[0 .. length) are "significant values" for the "current level" nodes
                // Invariant: bytes32(0) is the value for nodes with indexes [length .. 2**(HEIGHT-H))

                // Iterate over every pair of (leftChild, rightChild) on the current level
                for (uint256 leftIndex = 0; leftIndex < levelLength; leftIndex += 2) {
                    uint256 rightIndex = leftIndex + 1;
                    bytes32 leftChild = hashes[leftIndex];
                    // Note: rightChild might be ZERO
                    bytes32 rightChild = rightIndex < levelLength ? hashes[rightIndex] : bytes32(0);
                    // Record the parent hash in the same array. This will not affect
                    // further calculations for the same level: (leftIndex >> 1) <= leftIndex.
                    hashes[leftIndex >> 1] = getParent(leftChild, rightChild);
                }
                // Set length for the "parent level"
                levelLength = (levelLength + 1) >> 1;
                // Traverse to parent node
                index >>= 1;
            }
        }
    }

    /// @notice Returns the height of the tree having a given amount of leafs.
    function getHeight(uint256 leafs) internal pure returns (uint256 height) {
        uint256 amount = 1;
        while (amount < leafs) {
            unchecked {
                ++height;
            }
            amount <<= 1;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
    AgentNotActive,
    AgentNotFraudulent,
    AgentNotUnstaking,
    AgentNotActiveNorUnstaking,
    AgentUnknown
} from "../libs/Errors.sol";

// Here we define common enums and structures to enable their easier reusing later.

// ═══════════════════════════════ AGENT STATUS ════════════════════════════════

/// @dev Potential statuses for the off-chain bonded agent:
/// - Unknown: never provided a bond => signature not valid
/// - Active: has a bond in BondingManager => signature valid
/// - Unstaking: has a bond in BondingManager, initiated the unstaking => signature not valid
/// - Resting: used to have a bond in BondingManager, successfully unstaked => signature not valid
/// - Fraudulent: proven to commit fraud, value in Merkle Tree not updated => signature not valid
/// - Slashed: proven to commit fraud, value in Merkle Tree was updated => signature not valid
/// Unstaked agent could later be added back to THE SAME domain by staking a bond again.
/// Honest agent: Unknown -> Active -> unstaking -> Resting -> Active ...
/// Malicious agent: Unknown -> Active -> Fraudulent -> Slashed
/// Malicious agent: Unknown -> Active -> Unstaking -> Fraudulent -> Slashed
enum AgentFlag {
    Unknown,
    Active,
    Unstaking,
    Resting,
    Fraudulent,
    Slashed
}

/// @notice Struct for storing an agent in the BondingManager contract.
struct AgentStatus {
    AgentFlag flag;
    uint32 domain;
    uint32 index;
}
// 184 bits available for tight packing

using StructureUtils for AgentStatus global;

/// @notice Potential statuses of an agent in terms of being in dispute
/// - None: agent is not in dispute
/// - Pending: agent is in unresolved dispute
/// - Slashed: agent was in dispute that lead to agent being slashed
/// Note: agent who won the dispute has their status reset to None
enum DisputeFlag {
    None,
    Pending,
    Slashed
}

// ════════════════════════════════ DESTINATION ════════════════════════════════

/// @notice Struct representing the status of Destination contract.
/// @param snapRootTime     Timestamp when latest snapshot root was accepted
/// @param agentRootTime    Timestamp when latest agent root was accepted
/// @param notaryIndex      Index of Notary who signed the latest agent root
struct DestinationStatus {
    uint40 snapRootTime;
    uint40 agentRootTime;
    uint32 notaryIndex;
}

// ═══════════════════════════════ EXECUTION HUB ═══════════════════════════════

/// @notice Potential statuses of the message in Execution Hub.
/// - None: there hasn't been a valid attempt to execute the message yet
/// - Failed: there was a valid attempt to execute the message, but recipient reverted
/// - Success: there was a valid attempt to execute the message, and recipient did not revert
/// Note: message can be executed until its status is Success
enum MessageStatus {
    None,
    Failed,
    Success
}

library StructureUtils {
    /// @notice Checks that Agent is Active
    function verifyActive(AgentStatus memory status) internal pure {
        if (status.flag != AgentFlag.Active) {
            revert AgentNotActive();
        }
    }

    /// @notice Checks that Agent is Unstaking
    function verifyUnstaking(AgentStatus memory status) internal pure {
        if (status.flag != AgentFlag.Unstaking) {
            revert AgentNotUnstaking();
        }
    }

    /// @notice Checks that Agent is Active or Unstaking
    function verifyActiveUnstaking(AgentStatus memory status) internal pure {
        if (status.flag != AgentFlag.Active && status.flag != AgentFlag.Unstaking) {
            revert AgentNotActiveNorUnstaking();
        }
    }

    /// @notice Checks that Agent is Fraudulent
    function verifyFraudulent(AgentStatus memory status) internal pure {
        if (status.flag != AgentFlag.Fraudulent) {
            revert AgentNotFraudulent();
        }
    }

    /// @notice Checks that Agent is not Unknown
    function verifyKnown(AgentStatus memory status) internal pure {
        if (status.flag == AgentFlag.Unknown) {
            revert AgentUnknown();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// ══════════════════════════════ LIBRARY IMPORTS ══════════════════════════════
import {FRESH_DATA_TIMEOUT} from "../libs/Constants.sol";
import {
    CallerNotInbox,
    DisputeAlreadyResolved,
    DisputeNotOpened,
    DisputeNotStuck,
    IncorrectAgentDomain,
    IndexOutOfRange,
    GuardInDispute,
    NotaryInDispute
} from "../libs/Errors.sol";
import {AgentFlag, AgentStatus, DisputeFlag} from "../libs/Structures.sol";
// ═════════════════════════════ INTERNAL IMPORTS ══════════════════════════════
import {MessagingBase} from "../base/MessagingBase.sol";
import {AgentManagerEvents} from "../events/AgentManagerEvents.sol";
import {IAgentManager} from "../interfaces/IAgentManager.sol";
import {InterfaceDestination} from "../interfaces/InterfaceDestination.sol";
import {IStatementInbox} from "../interfaces/IStatementInbox.sol";

/// @notice `AgentManager` is used to keep track of all the bonded agents and their statuses.
/// The exact logic of how the agent statuses are stored and updated is implemented in child contracts,
/// and depends on whether the contract is used on Synapse Chain or on other chains.
/// `AgentManager` is responsible for the following:
/// - Keeping track of all the bonded agents and their statuses.
/// - Keeping track of all the disputes between agents.
/// - Notifying `AgentSecured` contracts about the opened and resolved disputes.
/// - Notifying `AgentSecured` contracts about the slashed agents.
abstract contract AgentManager is MessagingBase, AgentManagerEvents, IAgentManager {
    struct AgentDispute {
        DisputeFlag flag;
        uint88 disputePtr;
        address fraudProver;
    }

    // TODO: do we want to store the dispute timestamp?
    struct OpenedDispute {
        uint32 guardIndex;
        uint32 notaryIndex;
        uint32 slashedIndex;
    }

    // ══════════════════════════════════════════════════ STORAGE ══════════════════════════════════════════════════════

    address public origin;

    address public destination;

    address public inbox;

    // (agent index => their dispute status)
    mapping(uint256 => AgentDispute) internal _agentDispute;

    // All disputes ever opened
    OpenedDispute[] internal _disputes;

    /// @dev gap for upgrade safety
    uint256[45] private __GAP; // solhint-disable-line var-name-mixedcase

    modifier onlyInbox() {
        if (msg.sender != inbox) revert CallerNotInbox();
        _;
    }

    // ════════════════════════════════════════════════ INITIALIZER ════════════════════════════════════════════════════

    // solhint-disable-next-line func-name-mixedcase
    function __AgentManager_init(address origin_, address destination_, address inbox_) internal onlyInitializing {
        origin = origin_;
        destination = destination_;
        inbox = inbox_;
    }

    // ════════════════════════════════════════════════ ONLY OWNER ═════════════════════════════════════════════════════

    /// @inheritdoc IAgentManager
    // solhint-disable-next-line ordering
    function resolveStuckDispute(uint32 domain, address slashedAgent) external onlyOwner {
        AgentDispute memory slashedDispute = _agentDispute[_getIndex(slashedAgent)];
        if (slashedDispute.flag == DisputeFlag.None) revert DisputeNotOpened();
        if (slashedDispute.flag == DisputeFlag.Slashed) revert DisputeAlreadyResolved();
        // Check if there has been no fresh data from the Notaries for a while.
        (uint40 snapRootTime,,) = InterfaceDestination(destination).destStatus();
        if (block.timestamp < FRESH_DATA_TIMEOUT + snapRootTime) revert DisputeNotStuck();
        // This will revert if domain doesn't match the agent's domain.
        _slashAgent({domain: domain, agent: slashedAgent, prover: address(0)});
    }

    // ════════════════════════════════════════════════ ONLY INBOX ═════════════════════════════════════════════════════

    /// @inheritdoc IAgentManager
    function openDispute(uint32 guardIndex, uint32 notaryIndex) external onlyInbox {
        // Check that both agents are not in Dispute yet.
        if (_agentDispute[guardIndex].flag != DisputeFlag.None) revert GuardInDispute();
        if (_agentDispute[notaryIndex].flag != DisputeFlag.None) revert NotaryInDispute();
        _disputes.push(OpenedDispute(guardIndex, notaryIndex, 0));
        // Dispute is stored at length - 1, but we store the index + 1 to distinguish from "not in dispute".
        uint256 disputePtr = _disputes.length;
        _agentDispute[guardIndex] = AgentDispute(DisputeFlag.Pending, uint88(disputePtr), address(0));
        _agentDispute[notaryIndex] = AgentDispute(DisputeFlag.Pending, uint88(disputePtr), address(0));
        // Dispute index is length - 1. Note: report that initiated the dispute has the same index in `Inbox`.
        emit DisputeOpened({disputeIndex: disputePtr - 1, guardIndex: guardIndex, notaryIndex: notaryIndex});
        _notifyDisputeOpened(guardIndex, notaryIndex);
    }

    /// @inheritdoc IAgentManager
    function slashAgent(uint32 domain, address agent, address prover) external onlyInbox {
        _slashAgent(domain, agent, prover);
    }

    // ═══════════════════════════════════════════════════ VIEWS ═══════════════════════════════════════════════════════

    /// @inheritdoc IAgentManager
    function getAgent(uint256 index) external view returns (address agent, AgentStatus memory status) {
        agent = _getAgent(index);
        if (agent != address(0)) status = agentStatus(agent);
    }

    /// @inheritdoc IAgentManager
    function agentStatus(address agent) public view returns (AgentStatus memory status) {
        status = _storedAgentStatus(agent);
        // If agent was proven to commit fraud, but their slashing wasn't completed, return the Fraudulent flag.
        if (_agentDispute[_getIndex(agent)].flag == DisputeFlag.Slashed && status.flag != AgentFlag.Slashed) {
            status.flag = AgentFlag.Fraudulent;
        }
    }

    /// @inheritdoc IAgentManager
    function getDisputesAmount() external view returns (uint256) {
        return _disputes.length;
    }

    /// @inheritdoc IAgentManager
    function getDispute(uint256 index)
        external
        view
        returns (
            address guard,
            address notary,
            address slashedAgent,
            address fraudProver,
            bytes memory reportPayload,
            bytes memory reportSignature
        )
    {
        if (index >= _disputes.length) revert IndexOutOfRange();
        OpenedDispute memory dispute = _disputes[index];
        guard = _getAgent(dispute.guardIndex);
        notary = _getAgent(dispute.notaryIndex);
        if (dispute.slashedIndex > 0) {
            slashedAgent = _getAgent(dispute.slashedIndex);
            fraudProver = _agentDispute[dispute.slashedIndex].fraudProver;
        }
        (reportPayload, reportSignature) = IStatementInbox(inbox).getGuardReport(index);
    }

    /// @inheritdoc IAgentManager
    function disputeStatus(address agent)
        external
        view
        returns (DisputeFlag flag, address rival, address fraudProver, uint256 disputePtr)
    {
        uint256 agentIndex = _getIndex(agent);
        AgentDispute memory agentDispute = _agentDispute[agentIndex];
        flag = agentDispute.flag;
        fraudProver = agentDispute.fraudProver;
        disputePtr = agentDispute.disputePtr;
        if (disputePtr > 0) {
            OpenedDispute memory dispute = _disputes[disputePtr - 1];
            rival = _getAgent(dispute.guardIndex == agentIndex ? dispute.notaryIndex : dispute.guardIndex);
        }
    }

    // ══════════════════════════════════════════════ INTERNAL LOGIC ═══════════════════════════════════════════════════

    /// @dev Hook that is called after agent was slashed in AgentManager and AgentSecured contracts were notified.
    // solhint-disable-next-line no-empty-blocks
    function _afterAgentSlashed(uint32 domain, address agent, address prover) internal virtual {}

    /// @dev Child contract should implement the logic for notifying AgentSecured contracts about the opened dispute.
    function _notifyDisputeOpened(uint32 guardIndex, uint32 notaryIndex) internal virtual;

    /// @dev Child contract should implement the logic for notifying AgentSecured contracts about the resolved dispute.
    function _notifyDisputeResolved(uint32 slashedIndex, uint32 rivalIndex) internal virtual;

    /// @dev Slashes the Agent and notifies the local Destination and Origin contracts about the slashed agent.
    /// Should be called when the agent fraud was confirmed.
    function _slashAgent(uint32 domain, address agent, address prover) internal {
        // Check that agent is Active/Unstaking and that the domains match
        AgentStatus memory status = _storedAgentStatus(agent);
        status.verifyActiveUnstaking();
        if (status.domain != domain) revert IncorrectAgentDomain();
        // The "stored" agent status is not updated yet, however agentStatus() will return AgentFlag.Fraudulent
        emit StatusUpdated(AgentFlag.Fraudulent, domain, agent);
        // This will revert if the agent has been slashed earlier
        _resolveDispute(status.index, prover);
        // Call "after slash" hook - this allows Bonding/Light Manager to add custom "after slash" logic
        _afterAgentSlashed(domain, agent, prover);
    }

    /// @dev Resolves a Dispute between a slashed Agent and their Rival (if there was one).
    function _resolveDispute(uint32 slashedIndex, address prover) internal {
        AgentDispute memory agentDispute = _agentDispute[slashedIndex];
        if (agentDispute.flag == DisputeFlag.Slashed) revert DisputeAlreadyResolved();
        agentDispute.flag = DisputeFlag.Slashed;
        agentDispute.fraudProver = prover;
        _agentDispute[slashedIndex] = agentDispute;
        // Check if there was a opened dispute with the slashed agent
        uint32 rivalIndex = 0;
        if (agentDispute.disputePtr != 0) {
            uint256 disputeIndex = agentDispute.disputePtr - 1;
            OpenedDispute memory dispute = _disputes[disputeIndex];
            _disputes[disputeIndex].slashedIndex = slashedIndex;
            // Clear the dispute status for the rival
            rivalIndex = dispute.notaryIndex == slashedIndex ? dispute.guardIndex : dispute.notaryIndex;
            delete _agentDispute[rivalIndex];
            emit DisputeResolved(disputeIndex, slashedIndex, rivalIndex, prover);
        }
        _notifyDisputeResolved(slashedIndex, rivalIndex);
    }

    // ══════════════════════════════════════════════ INTERNAL VIEWS ═══════════════════════════════════════════════════

    /// @dev Generates leaf to be saved in the Agent Merkle Tree
    function _agentLeaf(AgentFlag flag, uint32 domain, address agent) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(flag, domain, agent));
    }

    /// @dev Returns the last known status for the agent from the Agent Merkle Tree.
    /// Note: the actual agent status (returned by `agentStatus()`) may differ, if agent fraud was proven.
    function _storedAgentStatus(address agent) internal view virtual returns (AgentStatus memory);

    /// @dev Returns agent address for the given index. Returns zero for non existing indexes.
    function _getAgent(uint256 index) internal view virtual returns (address);

    /// @dev Returns the index of the agent in the Agent Merkle Tree. Returns zero for non existing agents.
    function _getIndex(address agent) internal view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// ═════════════════════════════ INTERNAL IMPORTS ══════════════════════════════
import {MultiCallable} from "./MultiCallable.sol";
import {Versioned} from "./Version.sol";
// ═════════════════════════════ EXTERNAL IMPORTS ══════════════════════════════
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @notice Base contract for all messaging contracts.
 * - Provides context on the local chain's domain.
 * - Provides ownership functionality.
 * - Will be providing pausing functionality when it is implemented.
 */
abstract contract MessagingBase is MultiCallable, Versioned, OwnableUpgradeable {
    // ════════════════════════════════════════════════ IMMUTABLES ═════════════════════════════════════════════════════

    /// @notice Domain of the local chain, set once upon contract creation
    uint32 public immutable localDomain;

    // ══════════════════════════════════════════════════ STORAGE ══════════════════════════════════════════════════════

    /// @dev gap for upgrade safety
    uint256[50] private __GAP; // solhint-disable-line var-name-mixedcase

    constructor(string memory version_, uint32 localDomain_) Versioned(version_) {
        localDomain = localDomain_;
    }

    // TODO: Implement pausing

    /**
     * @dev Should be impossible to renounce ownership;
     * we override OpenZeppelin OwnableUpgradeable's
     * implementation of renounceOwnership to make it a no-op
     */
    function renounceOwnership() public override onlyOwner {} //solhint-disable-line no-empty-blocks
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {AgentStatus} from "../libs/Structures.sol";

interface IAgentSecured {
    /**
     * @notice Local AgentManager should call this function to indicate that a dispute
     * between a Guard and a Notary has been opened.
     * @param guardIndex    Index of the Guard in the Agent Merkle Tree
     * @param notaryIndex   Index of the Notary in the Agent Merkle Tree
     */
    function openDispute(uint32 guardIndex, uint32 notaryIndex) external;

    /**
     * @notice Local AgentManager should call this function to indicate that a dispute
     * has been resolved due to one of the agents being slashed.
     * > `rivalIndex` will be ZERO, if the slashed agent was not in the Dispute.
     * @param slashedIndex  Index of the slashed agent in the Agent Merkle Tree
     * @param rivalIndex    Index of the their Dispute Rival in the Agent Merkle Tree
     */
    function resolveDispute(uint32 slashedIndex, uint32 rivalIndex) external;

    // ═══════════════════════════════════════════════════ VIEWS ═══════════════════════════════════════════════════════

    /**
     * @notice Returns the address of the local AgentManager contract, which is treated as
     * the "source of truth" for agent statuses.
     */
    function agentManager() external view returns (address);

    /**
     * @notice Returns the address of the local Inbox contract, which is treated as
     * the "source of truth" for agent-signed statements.
     * @dev Inbox passes verified agent statements to `IAgentSecured` contract.
     */
    function inbox() external view returns (address);

    /**
     * @notice Returns (flag, domain, index) for a given agent. See Structures.sol for details.
     * @dev Will return AgentFlag.Fraudulent for agents that have been proven to commit fraud,
     * but their status is not updated to Slashed yet.
     * @param agent     Agent address
     * @return          Status for the given agent: (flag, domain, index).
     */
    function agentStatus(address agent) external view returns (AgentStatus memory);

    /**
     * @notice Returns agent address and their current status for a given agent index.
     * @dev Will return empty values if agent with given index doesn't exist.
     * @param index     Agent index in the Agent Merkle Tree
     * @return agent    Agent address
     * @return status   Status for the given agent: (flag, domain, index)
     */
    function getAgent(uint256 index) external view returns (address agent, AgentStatus memory status);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface InterfaceBondingManager {
    // ═══════════════════════════════════════════════ AGENTS LOGIC ════════════════════════════════════════════════════

    /**
     * @notice Adds a new agent for the domain. This is either a fresh address (Inactive),
     * or an agent who used to be active on the same domain before (Resting).
     * @dev Inactive: `proof` should be the proof of inclusion of an empty leaf
     * having index following the last added agent in the tree.
     * @dev Resting: `proof` should be the proof of inclusion of the agent leaf
     * with Resting flag having index previously assigned to the agent.
     * @param domain    Domain where the Agent will be active
     * @param agent     Address of the Agent
     * @param proof     Merkle proof of the Inactive/Resting status for the agent
     */
    function addAgent(uint32 domain, address agent, bytes32[] memory proof) external;

    /**
     * @notice Initiates the unstaking of the agent bond. Agent signature is immediately no longer
     * considered valid on Synapse Chain, and will be invalid on other chains once the Light Manager
     * updates their agent merkle root on these chains.
     * @dev `proof` should be the proof of inclusion of the agent leaf
     * with Active flag having index previously assigned to the agent.
     * @param domain    Domain where the Agent is active
     * @param agent     Address of the Agent
     * @param proof     Merkle proof of the Active status for the agent
     */
    function initiateUnstaking(uint32 domain, address agent, bytes32[] memory proof) external;

    /**
     * @notice Completes the unstaking of the agent bond. Agent signature is no longer considered
     * valid on any of the chains.
     * @dev `proof` should be the proof of inclusion of the agent leaf
     * with Unstaking flag having index previously assigned to the agent.
     * @param domain    Domain where the Agent was active
     * @param agent     Address of the Agent
     * @param proof     Merkle proof of the unstaking status for the agent
     */
    function completeUnstaking(uint32 domain, address agent, bytes32[] memory proof) external;

    /**
     * @notice Completes the slashing of the agent bond. Agent signature is no longer considered
     * valid under the updated Agent Merkle Root.
     * @dev `proof` should be the proof of inclusion of the agent leaf
     * with Active/Unstaking flag having index previously assigned to the agent.
     * @param domain    Domain where the Agent was active
     * @param agent     Address of the Agent
     * @param proof     Merkle proof of the active/unstaking status for the agent
     */
    function completeSlashing(uint32 domain, address agent, bytes32[] memory proof) external;

    /**
     * @notice Remote AgentManager should call this function to indicate that the agent
     * has been proven to commit fraud on the origin chain.
     * @dev This initiates the process of agent slashing. It could be immediately
     * completed by anyone calling completeSlashing() providing a correct merkle proof
     * for the OLD agent status.
     * Note: as an extra security check this function returns its own selector, so that
     * Destination could verify that a "remote" function was called when executing a manager message.
     * @param domain        Domain where the slashed agent was active
     * @param agent         Address of the slashed Agent
     * @param prover        Address that initially provided fraud proof to remote AgentManager
     * @return magicValue   Selector of this function
     */
    function remoteSlashAgent(uint32 msgOrigin, uint256 proofMaturity, uint32 domain, address agent, address prover)
        external
        returns (bytes4 magicValue);

    /**
     * @notice Withdraws locked base message tips from requested domain Origin to the recipient.
     * Issues a call to a local Origin contract, or sends a manager message to the remote chain.
     * @dev Could only be called by the Summit contract.
     * @param recipient     Address to withdraw tips to
     * @param origin        Domain where tips need to be withdrawn
     * @param amount        Tips value to withdraw
     */
    function withdrawTips(address recipient, uint32 origin, uint256 amount) external;

    // ═══════════════════════════════════════════════════ VIEWS ═══════════════════════════════════════════════════════

    /**
     * @notice Returns all active agents for a given domain.
     * @param domain    Domain to get agents from (ZERO for Guards)
     * @param agents    List of active agents for the domain
     */
    function getActiveAgents(uint32 domain) external view returns (address[] memory agents);

    /**
     * @notice Returns a leaf representing the current status of agent in the Agent Merkle Tree.
     * @dev Will return an empty leaf, if agent is not added to the tree yet.
     * @param agent     Agent address
     * @return leaf     Agent leaf in the Agent Merkle Tree
     */
    function agentLeaf(address agent) external view returns (bytes32 leaf);

    /**
     * @notice Returns a total amount of leafs representing known agents.
     * @dev This includes active, unstaking, resting and slashed agents.
     * This also includes an empty leaf as the very first entry.
     */
    function leafsAmount() external view returns (uint256 amount);

    /**
     * @notice Returns a full list of leafs from the Agent Merkle Tree.
     * @dev This might consume a lot of gas, do not use this on-chain.
     */
    function allLeafs() external view returns (bytes32[] memory leafs);

    /**
     * @notice Returns a list of leafs from the Agent Merkle Tree
     * with indexes [indexFrom .. indexFrom + amount).
     * @dev This might consume a lot of gas, do not use this on-chain.
     * @dev Will return less than `amount` entries, if indexFrom + amount > leafsAmount
     */
    function getLeafs(uint256 indexFrom, uint256 amount) external view returns (bytes32[] memory leafs);

    /**
     * @notice Returns a proof of inclusion of the agent in the Agent Merkle Tree.
     * @dev Will return a proof for an empty leaf, if agent is not added to the tree yet.
     * This proof could be used by ANY next new agent that calls {addAgent}.
     * @dev This WILL consume a lot of gas, do not use this on-chain.
     * @dev The alternative way to create a proof is to fetch the full list of leafs using
     * either {allLeafs} or {getLeafs}, and create a merkle proof from that.
     * @param agent     Agent address
     * @return proof    Merkle proof for the agent
     */
    function getProof(address agent) external view returns (bytes32[] memory proof);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {AgentStatus} from "../libs/Structures.sol";

interface InterfaceLightManager {
    /**
     * @notice Updates agent status, using a proof against the latest known Agent Merkle Root.
     * @dev Will revert if the provided proof doesn't match the latest merkle root.
     * @param agent     Agent address
     * @param status    Structure specifying agent status: (flag, domain, index)
     * @param proof     Merkle proof of Active status for the agent
     */
    function updateAgentStatus(address agent, AgentStatus memory status, bytes32[] memory proof) external;

    /**
     * @notice Updates the root of Agent Merkle Tree that the Light Manager is tracking.
     * Could be only called by a local Destination contract, which is supposed to
     * verify the attested Agent Merkle Roots.
     * @param agentRoot     New Agent Merkle Root
     */
    function setAgentRoot(bytes32 agentRoot) external;

    /**
     * @notice Withdraws locked base message tips from local Origin to the recipient.
     * @dev Could only be remote-called by BondingManager contract on Synapse Chain.
     * Note: as an extra security check this function returns its own selector, so that
     * Destination could verify that a "remote" function was called when executing a manager message.
     * @param recipient     Address to withdraw tips to
     * @param amount        Tips value to withdraw
     */
    function remoteWithdrawTips(uint32 msgOrigin, uint256 proofMaturity, address recipient, uint256 amount)
        external
        returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface InterfaceOrigin {
    // ═══════════════════════════════════════════════ SEND MESSAGES ═══════════════════════════════════════════════════

    /**
     * @notice Send a message to the recipient located on destination domain.
     * @dev Recipient has to conform to IMessageRecipient interface, otherwise message won't be delivered.
     * @param destination           Domain of destination chain
     * @param recipient             Address of recipient on destination chain as bytes32
     * @param optimisticPeriod      Optimistic period for message execution on destination chain
     * @param paddedRequest         Padded encoded message execution request on destination chain
     * @param content               Raw bytes content of message
     * @return messageNonce         Nonce of the sent message
     * @return messageHash          Hash of the sent message
     */
    function sendBaseMessage(
        uint32 destination,
        bytes32 recipient,
        uint32 optimisticPeriod,
        uint256 paddedRequest,
        bytes memory content
    ) external payable returns (uint32 messageNonce, bytes32 messageHash);

    /**
     * @notice Send a manager message to the destination domain.
     * @dev This could only be called by AgentManager, which takes care of encoding the calldata payload.
     * Note: (msgOrigin, proofMaturity) security args will be added to payload on the destination chain
     * so that the AgentManager could verify where the Manager Message came from and how mature is the proof.
     * Note: function is not payable, as no tips are required for sending a manager message.
     * @param destination           Domain of destination chain
     * @param optimisticPeriod      Optimistic period for message execution on destination chain
     * @param payload               Payload for calling AgentManager on destination chain (with extra security args)
     */
    function sendManagerMessage(uint32 destination, uint32 optimisticPeriod, bytes memory payload)
        external
        returns (uint32 messageNonce, bytes32 messageHash);

    // ════════════════════════════════════════════════ TIPS LOGIC ═════════════════════════════════════════════════════

    /**
     * @notice Withdraws locked base message tips to the recipient.
     * @dev Could only be called by a local AgentManager.
     * @param recipient     Address to withdraw tips to
     * @param amount        Tips value to withdraw
     */
    function withdrawTips(address recipient, uint256 amount) external;

    // ═══════════════════════════════════════════════════ VIEWS ═══════════════════════════════════════════════════════

    /**
     * @notice Returns the minimum tips value for sending a message to a given destination.
     * @dev Using at least `tipsValue` as `msg.value` for `sendBaseMessage()`
     * will guarantee that the message will be accepted.
     * @param destination       Domain of destination chain
     * @param paddedRequest     Padded encoded message execution request on destination chain
     * @param contentLength     The length of the message content
     * @return tipsValue        Minimum tips value for a message to be accepted
     */
    function getMinimumTipsValue(uint32 destination, uint256 paddedRequest, uint256 contentLength)
        external
        view
        returns (uint256 tipsValue);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {AgentFlag} from "../libs/Structures.sol";

abstract contract AgentManagerEvents {
    /**
     * @notice Emitted whenever a Dispute is opened between two agents. This happens when a Guard submits
     * their report for the Notary-signed statement to `StatementInbox`.
     * @param disputeIndex  Index of the dispute in the global list of all opened disputes
     * @param guardIndex    Index of the Guard in the Agent Merkle Tree
     * @param notaryIndex   Index of the Notary in the Agent Merkle Tree
     */
    event DisputeOpened(uint256 disputeIndex, uint32 guardIndex, uint32 notaryIndex);

    /**
     * @notice Emitted whenever a Dispute is resolved. This happens when an Agent who was in Dispute is slashed.
     * Note: this won't be emitted, if an Agent was slashed without being in Dispute.
     * @param disputeIndex  Index of the dispute in the global list of all opened disputes
     * @param slashedIndex  Index of the slashed agent in the Agent Merkle Tree
     * @param rivalIndex    Index of the rival agent in the Agent Merkle Tree
     * @param fraudProver   Address who provided fraud proof to resolve the Dispute
     */
    event DisputeResolved(uint256 disputeIndex, uint32 slashedIndex, uint32 rivalIndex, address fraudProver);

    // ═══════════════════════════════════════════════ DATA UPDATED ════════════════════════════════════════════════════

    /**
     * @notice Emitted whenever the root of the Agent Merkle Tree is updated.
     * @param newRoot   New agent merkle root
     */
    event RootUpdated(bytes32 newRoot);

    /**
     * @notice Emitted whenever a status of the agent is updated.
     * @dev Only Active/Unstaking/Resting/Slashed flags could be stored in the Agent Merkle Tree.
     * Unknown flag is the default (zero) value and is used to represent agents that never
     * interacted with the BondingManager contract.
     * Fraudulent flag is the value for the agent who has been proven to commit fraud, but their
     * status hasn't been updated to Slashed in the Agent Merkle Tree. This is due to the fact
     * that the update of the status requires a merkle proof of the old status, and happens
     * in a separate transaction because of that.
     * @param flag      Flag defining agent status:
     * @param domain    Domain assigned to the agent (ZERO for Guards)
     * @param agent     Agent address
     */
    event StatusUpdated(AgentFlag flag, uint32 indexed domain, address indexed agent);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {AgentStatus, DisputeFlag} from "../libs/Structures.sol";

interface IAgentManager {
    /**
     * @notice Allows Inbox to open a Dispute between a Guard and a Notary, if they are both not in Dispute already.
     * > Will revert if any of these is true:
     * > - Caller is not Inbox.
     * > - Guard or Notary is already in Dispute.
     * @param guardIndex    Index of the Guard in the Agent Merkle Tree
     * @param notaryIndex   Index of the Notary in the Agent Merkle Tree
     */
    function openDispute(uint32 guardIndex, uint32 notaryIndex) external;

    /**
     * @notice Allows contract owner to resolve a stuck Dispute.
     * This could only be called if no fresh data has been submitted by the Notaries to the Inbox,
     * which is required for the Dispute to be resolved naturally.
     * > Will revert if any of these is true:
     * > - Caller is not contract owner.
     * > - Domain doesn't match the saved agent domain.
     * > - `slashedAgent` is not in Dispute.
     * > - Less than `FRESH_DATA_TIMEOUT` has passed since the last Notary submission to the Inbox.
     * @param slashedAgent  Agent that is being slashed
     */
    function resolveStuckDispute(uint32 domain, address slashedAgent) external;

    /**
     * @notice Allows Inbox to slash an agent, if their fraud was proven.
     * > Will revert if any of these is true:
     * > - Caller is not Inbox.
     * > - Domain doesn't match the saved agent domain.
     * @param domain    Domain where the Agent is active
     * @param agent     Address of the Agent
     * @param prover    Address that initially provided fraud proof
     */
    function slashAgent(uint32 domain, address agent, address prover) external;

    // ═══════════════════════════════════════════════════ VIEWS ═══════════════════════════════════════════════════════

    /**
     * @notice Returns the latest known root of the Agent Merkle Tree.
     */
    function agentRoot() external view returns (bytes32);

    /**
     * @notice Returns (flag, domain, index) for a given agent. See Structures.sol for details.
     * @dev Will return AgentFlag.Fraudulent for agents that have been proven to commit fraud,
     * but their status is not updated to Slashed yet.
     * @param agent     Agent address
     * @return          Status for the given agent: (flag, domain, index).
     */
    function agentStatus(address agent) external view returns (AgentStatus memory);

    /**
     * @notice Returns agent address and their current status for a given agent index.
     * @dev Will return empty values if agent with given index doesn't exist.
     * @param index     Agent index in the Agent Merkle Tree
     * @return agent    Agent address
     * @return status   Status for the given agent: (flag, domain, index)
     */
    function getAgent(uint256 index) external view returns (address agent, AgentStatus memory status);

    /**
     * @notice Returns the number of opened Disputes.
     * @dev This includes the Disputes that have been resolved already.
     */
    function getDisputesAmount() external view returns (uint256);

    /**
     * @notice Returns information about the dispute with the given index.
     * @dev Will revert if dispute with given index hasn't been opened yet.
     * @param index             Dispute index
     * @return guard            Address of the Guard in the Dispute
     * @return notary           Address of the Notary in the Dispute
     * @return slashedAgent     Address of the Agent who was slashed when Dispute was resolved
     * @return fraudProver      Address who provided fraud proof to resolve the Dispute
     * @return reportPayload    Raw payload with report data that led to the Dispute
     * @return reportSignature  Guard signature for the report payload
     */
    function getDispute(uint256 index)
        external
        view
        returns (
            address guard,
            address notary,
            address slashedAgent,
            address fraudProver,
            bytes memory reportPayload,
            bytes memory reportSignature
        );

    /**
     * @notice Returns the current Dispute status of a given agent. See Structures.sol for details.
     * @dev Every returned value will be set to zero if agent was not slashed and is not in Dispute.
     * `rival` and `disputePtr` will be set to zero if the agent was slashed without being in Dispute.
     * @param agent         Agent address
     * @return flag         Flag describing the current Dispute status for the agent: None/Pending/Slashed
     * @return rival        Address of the rival agent in the Dispute
     * @return fraudProver  Address who provided fraud proof to resolve the Dispute
     * @return disputePtr   Index of the opened Dispute PLUS ONE. Zero if agent is not in Dispute.
     */
    function disputeStatus(address agent)
        external
        view
        returns (DisputeFlag flag, address rival, address fraudProver, uint256 disputePtr);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ChainGas, GasData} from "../libs/stack/GasData.sol";

interface InterfaceDestination {
    /**
     * @notice Attempts to pass a quarantined Agent Merkle Root to a local Light Manager.
     * @dev Will do nothing, if root optimistic period is not over.
     * Note: both returned values can not be true.
     * @return rootPassed   Whether the agent merkle root was passed to LightManager
     * @return rootPending  Whether there is a pending agent merkle root left
     */
    function passAgentRoot() external returns (bool rootPassed, bool rootPending);

    /**
     * @notice Accepts an attestation, which local `AgentManager` verified to have been signed
     * by an active Notary for this chain.
     * > Attestation is created whenever a Notary-signed snapshot is saved in Summit on Synapse Chain.
     * - Saved Attestation could be later used to prove the inclusion of message in the Origin Merkle Tree.
     * - Messages coming from chains included in the Attestation's snapshot could be proven.
     * - Proof only exists for messages that were sent prior to when the Attestation's snapshot was taken.
     * > Will revert if any of these is true:
     * > - Called by anyone other than local `AgentManager`.
     * > - Attestation payload is not properly formatted.
     * > - Attestation signer is in Dispute.
     * > - Attestation's snapshot root has been previously submitted.
     * Note: agentRoot and snapGas have been verified by the local `AgentManager`.
     * @param notaryIndex       Index of Attestation Notary in Agent Merkle Tree
     * @param sigIndex          Index of stored Notary signature
     * @param attPayload        Raw payload with Attestation data
     * @param agentRoot         Agent Merkle Root from the Attestation
     * @param snapGas           Gas data for each chain in the Attestation's snapshot
     * @return wasAccepted      Whether the Attestation was accepted
     */
    function acceptAttestation(
        uint32 notaryIndex,
        uint256 sigIndex,
        bytes memory attPayload,
        bytes32 agentRoot,
        ChainGas[] memory snapGas
    ) external returns (bool wasAccepted);

    // ═══════════════════════════════════════════════════ VIEWS ═══════════════════════════════════════════════════════

    /**
     * @notice Returns the total amount of Notaries attestations that have been accepted.
     */
    function attestationsAmount() external view returns (uint256);

    /**
     * @notice Returns a Notary-signed attestation with a given index.
     * > Index refers to the list of all attestations accepted by this contract.
     * @dev Attestations are created on Synapse Chain whenever a Notary-signed snapshot is accepted by Summit.
     * Will return an empty signature if this contract is deployed on Synapse Chain.
     * @param index             Attestation index
     * @return attPayload       Raw payload with Attestation data
     * @return attSignature     Notary signature for the reported attestation
     */
    function getAttestation(uint256 index) external view returns (bytes memory attPayload, bytes memory attSignature);

    /**
     * @notice Returns the gas data for a given chain from the latest accepted attestation with that chain.
     * @dev Will return empty values if there is no data for the domain,
     * or if the notary who provided the data is in dispute.
     * @param domain            Domain for the chain
     * @return gasData          Gas data for the chain
     * @return dataMaturity     Gas data age in seconds
     */
    function getGasData(uint32 domain) external view returns (GasData gasData, uint256 dataMaturity);

    /**
     * Returns status of Destination contract as far as snapshot/agent roots are concerned
     * @return snapRootTime     Timestamp when latest snapshot root was accepted
     * @return agentRootTime    Timestamp when latest agent root was accepted
     * @return notaryIndex      Index of Notary who signed the latest agent root
     */
    function destStatus() external view returns (uint40 snapRootTime, uint40 agentRootTime, uint32 notaryIndex);

    /**
     * Returns Agent Merkle Root to be passed to LightManager once its optimistic period is over.
     */
    function nextAgentRoot() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IStatementInbox {
    // ══════════════════════════════════════════ SUBMIT AGENT STATEMENTS ══════════════════════════════════════════════

    /**
     * @notice Accepts a Guard's state report signature, a Snapshot containing the reported State,
     * as well as Notary signature for the Snapshot.
     * > StateReport is a Guard statement saying "Reported state is invalid".
     * - This results in an opened Dispute between the Guard and the Notary.
     * - Note: Guard could (but doesn't have to) form a StateReport and use other values from
     * `verifyStateWithSnapshot()` successful call that led to Notary being slashed in remote Origin.
     * > Will revert if any of these is true:
     * > - State Report signer is not an active Guard.
     * > - Snapshot payload is not properly formatted.
     * > - Snapshot signer is not an active Notary.
     * > - State index is out of range.
     * > - The Guard or the Notary are already in a Dispute
     * @param stateIndex        Index of the reported State in the Snapshot
     * @param srSignature       Guard signature for the report
     * @param snapPayload       Raw payload with Snapshot data
     * @param snapSignature     Notary signature for the Snapshot
     * @return wasAccepted      Whether the Report was accepted (resulting in Dispute between the agents)
     */
    function submitStateReportWithSnapshot(
        uint256 stateIndex,
        bytes memory srSignature,
        bytes memory snapPayload,
        bytes memory snapSignature
    ) external returns (bool wasAccepted);

    /**
     * @notice Accepts a Guard's state report signature, a Snapshot containing the reported State,
     * as well as Notary signature for the Attestation created from this Snapshot.
     * > StateReport is a Guard statement saying "Reported state is invalid".
     * - This results in an opened Dispute between the Guard and the Notary.
     * - Note: Guard could (but doesn't have to) form a StateReport and use other values from
     * `verifyStateWithAttestation()` successful call that led to Notary being slashed in remote Origin.
     * > Will revert if any of these is true:
     * > - State Report signer is not an active Guard.
     * > - Snapshot payload is not properly formatted.
     * > - State index is out of range.
     * > - Attestation payload is not properly formatted.
     * > - Attestation signer is not an active Notary.
     * > - Attestation's snapshot root is not equal to Merkle Root derived from the Snapshot.
     * > - The Guard or the Notary are already in a Dispute
     * @param stateIndex        Index of the reported State in the Snapshot
     * @param srSignature       Guard signature for the report
     * @param snapPayload       Raw payload with Snapshot data
     * @param attPayload        Raw payload with Attestation data
     * @param attSignature      Notary signature for the Attestation
     * @return wasAccepted      Whether the Report was accepted (resulting in Dispute between the agents)
     */
    function submitStateReportWithAttestation(
        uint256 stateIndex,
        bytes memory srSignature,
        bytes memory snapPayload,
        bytes memory attPayload,
        bytes memory attSignature
    ) external returns (bool wasAccepted);

    /**
     * @notice Accepts a Guard's state report signature, a proof of inclusion of the reported State in an Attestation,
     * as well as Notary signature for the Attestation.
     * > StateReport is a Guard statement saying "Reported state is invalid".
     * - This results in an opened Dispute between the Guard and the Notary.
     * - Note: Guard could (but doesn't have to) form a StateReport and use other values from
     * `verifyStateWithSnapshotProof()` successful call that led to Notary being slashed in remote Origin.
     * > Will revert if any of these is true:
     * > - State payload is not properly formatted.
     * > - State Report signer is not an active Guard.
     * > - Attestation payload is not properly formatted.
     * > - Attestation signer is not an active Notary.
     * > - Attestation's snapshot root is not equal to Merkle Root derived from State and Snapshot Proof.
     * > - Snapshot Proof's first element does not match the State metadata.
     * > - Snapshot Proof length exceeds Snapshot Tree Height.
     * > - State index is out of range.
     * > - The Guard or the Notary are already in a Dispute
     * @param stateIndex        Index of the reported State in the Snapshot
     * @param statePayload      Raw payload with State data that Guard reports as invalid
     * @param srSignature       Guard signature for the report
     * @param snapProof         Proof of inclusion of reported State's Left Leaf into Snapshot Merkle Tree
     * @param attPayload        Raw payload with Attestation data
     * @param attSignature      Notary signature for the Attestation
     * @return wasAccepted      Whether the Report was accepted (resulting in Dispute between the agents)
     */
    function submitStateReportWithSnapshotProof(
        uint256 stateIndex,
        bytes memory statePayload,
        bytes memory srSignature,
        bytes32[] memory snapProof,
        bytes memory attPayload,
        bytes memory attSignature
    ) external returns (bool wasAccepted);

    // ══════════════════════════════════════════ VERIFY AGENT STATEMENTS ══════════════════════════════════════════════

    /**
     * @notice Verifies a message receipt signed by the Notary.
     * - Does nothing, if the receipt is valid (matches the saved receipt data for the referenced message).
     * - Slashes the Notary, if the receipt is invalid.
     * > Will revert if any of these is true:
     * > - Receipt payload is not properly formatted.
     * > - Receipt signer is not an active Notary.
     * > - Receipt's destination chain does not refer to this chain.
     * @param rcptPayload       Raw payload with Receipt data
     * @param rcptSignature     Notary signature for the receipt
     * @return isValidReceipt   Whether the provided receipt is valid.
     *                          Notary is slashed, if return value is FALSE.
     */
    function verifyReceipt(bytes memory rcptPayload, bytes memory rcptSignature)
        external
        returns (bool isValidReceipt);

    /**
     * @notice Verifies a Guard's receipt report signature.
     * - Does nothing, if the report is valid (if the reported receipt is invalid).
     * - Slashes the Guard, if the report is invalid (if the reported receipt is valid).
     * > Will revert if any of these is true:
     * > - Receipt payload is not properly formatted.
     * > - Receipt Report signer is not an active Guard.
     * > - Receipt does not refer to this chain.
     * @param rcptPayload       Raw payload with Receipt data that Guard reports as invalid
     * @param rrSignature       Guard signature for the report
     * @return isValidReport    Whether the provided report is valid.
     *                          Guard is slashed, if return value is FALSE.
     */
    function verifyReceiptReport(bytes memory rcptPayload, bytes memory rrSignature)
        external
        returns (bool isValidReport);

    /**
     * @notice Verifies a state from the snapshot, that was used for the Notary-signed attestation.
     * - Does nothing, if the state is valid (matches the historical state of this contract).
     * - Slashes the Notary, if the state is invalid.
     * > Will revert if any of these is true:
     * > - Attestation payload is not properly formatted.
     * > - Attestation signer is not an active Notary.
     * > - Attestation's snapshot root is not equal to Merkle Root derived from the Snapshot.
     * > - Snapshot payload is not properly formatted.
     * > - State index is out of range.
     * > - State does not refer to this chain.
     * @param stateIndex        State index to check
     * @param snapPayload       Raw payload with snapshot data
     * @param attPayload        Raw payload with Attestation data
     * @param attSignature      Notary signature for the attestation
     * @return isValidState     Whether the provided state is valid.
     *                          Notary is slashed, if return value is FALSE.
     */
    function verifyStateWithAttestation(
        uint256 stateIndex,
        bytes memory snapPayload,
        bytes memory attPayload,
        bytes memory attSignature
    ) external returns (bool isValidState);

    /**
     * @notice Verifies a state from the snapshot, that was used for the Notary-signed attestation.
     * - Does nothing, if the state is valid (matches the historical state of this contract).
     * - Slashes the Notary, if the state is invalid.
     * > Will revert if any of these is true:
     * > - Attestation payload is not properly formatted.
     * > - Attestation signer is not an active Notary.
     * > - Attestation's snapshot root is not equal to Merkle Root derived from State and Snapshot Proof.
     * > - Snapshot Proof's first element does not match the State metadata.
     * > - Snapshot Proof length exceeds Snapshot Tree Height.
     * > - State payload is not properly formatted.
     * > - State index is out of range.
     * > - State does not refer to this chain.
     * @param stateIndex        Index of state in the snapshot
     * @param statePayload      Raw payload with State data to check
     * @param snapProof         Proof of inclusion of provided State's Left Leaf into Snapshot Merkle Tree
     * @param attPayload        Raw payload with Attestation data
     * @param attSignature      Notary signature for the attestation
     * @return isValidState     Whether the provided state is valid.
     *                          Notary is slashed, if return value is FALSE.
     */
    function verifyStateWithSnapshotProof(
        uint256 stateIndex,
        bytes memory statePayload,
        bytes32[] memory snapProof,
        bytes memory attPayload,
        bytes memory attSignature
    ) external returns (bool isValidState);

    /**
     * @notice Verifies a state from the snapshot (a list of states) signed by a Guard or a Notary.
     * - Does nothing, if the state is valid (matches the historical state of this contract).
     * - Slashes the Agent, if the state is invalid.
     * > Will revert if any of these is true:
     * > - Snapshot payload is not properly formatted.
     * > - Snapshot signer is not an active Agent.
     * > - State index is out of range.
     * > - State does not refer to this chain.
     * @param stateIndex        State index to check
     * @param snapPayload       Raw payload with snapshot data
     * @param snapSignature     Agent signature for the snapshot
     * @return isValidState     Whether the provided state is valid.
     *                          Agent is slashed, if return value is FALSE.
     */
    function verifyStateWithSnapshot(uint256 stateIndex, bytes memory snapPayload, bytes memory snapSignature)
        external
        returns (bool isValidState);

    /**
     * @notice Verifies a Guard's state report signature.
     *  - Does nothing, if the report is valid (if the reported state is invalid).
     *  - Slashes the Guard, if the report is invalid (if the reported state is valid).
     * > Will revert if any of these is true:
     * > - State payload is not properly formatted.
     * > - State Report signer is not an active Guard.
     * > - Reported State does not refer to this chain.
     * @param statePayload      Raw payload with State data that Guard reports as invalid
     * @param srSignature       Guard signature for the report
     * @return isValidReport    Whether the provided report is valid.
     *                          Guard is slashed, if return value is FALSE.
     */
    function verifyStateReport(bytes memory statePayload, bytes memory srSignature)
        external
        returns (bool isValidReport);

    // ═══════════════════════════════════════════════════ VIEWS ═══════════════════════════════════════════════════════

    /**
     * @notice Returns the amount of Guard Reports stored in StatementInbox.
     * > Only reports that led to opening a Dispute are stored.
     */
    function getReportsAmount() external view returns (uint256);

    /**
     * @notice Returns the Guard report with the given index stored in StatementInbox.
     * > Only reports that led to opening a Dispute are stored.
     * @dev Will revert if report with given index doesn't exist.
     * @param index             Report index
     * @return statementPayload Raw payload with statement that Guard reported as invalid
     * @return reportSignature  Guard signature for the report
     */
    function getGuardReport(uint256 index)
        external
        view
        returns (bytes memory statementPayload, bytes memory reportSignature);

    /**
     * @notice Returns the signature with the given index stored in StatementInbox.
     * @dev Will revert if signature with given index doesn't exist.
     * @param index     Signature index
     * @return          Raw payload with signature
     */
    function getStoredSignature(uint256 index) external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {MulticallFailed} from "../libs/Errors.sol";

/// @notice Collection of Multicall utilities. Fork of Multicall3:
/// https://github.com/mds1/multicall/blob/master/src/Multicall3.sol
abstract contract MultiCallable {
    struct Call {
        bool allowFailure;
        bytes callData;
    }

    struct Result {
        bool success;
        bytes returnData;
    }

    /// @notice Aggregates a few calls to this contract into one multicall without modifying `msg.sender`.
    function multicall(Call[] calldata calls) external returns (Result[] memory callResults) {
        uint256 amount = calls.length;
        callResults = new Result[](amount);
        Call calldata call_;
        for (uint256 i = 0; i < amount;) {
            call_ = calls[i];
            Result memory result = callResults[i];
            // We perform a delegate call to ourselves here. Delegate call does not modify `msg.sender`, so
            // this will have the same effect as if `msg.sender` performed all the calls themselves one by one.
            // solhint-disable-next-line avoid-low-level-calls
            (result.success, result.returnData) = address(this).delegatecall(call_.callData);
            // solhint-disable-next-line no-inline-assembly
            assembly {
                // Revert if the call fails and failure is not allowed
                // `allowFailure := calldataload(call_)` and `success := mload(result)`
                if iszero(or(calldataload(call_), mload(result))) {
                    // Revert with `0x4d6a2328` (function selector for `MulticallFailed()`)
                    mstore(0x00, 0x4d6a232800000000000000000000000000000000000000000000000000000000)
                    revert(0x00, 0x04)
                }
            }
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IncorrectVersionLength} from "../libs/Errors.sol";

/**
 * @title Versioned
 * @notice Version getter for contracts. Doesn't use any storage slots, meaning
 * it will never cause any troubles with the upgradeable contracts. For instance, this contract
 * can be added or removed from the inheritance chain without shifting the storage layout.
 */
abstract contract Versioned {
    /**
     * @notice Struct that is mimicking the storage layout of a string with 32 bytes or less.
     * Length is limited by 32, so the whole string payload takes two memory words:
     * @param length    String length
     * @param data      String characters
     */
    struct _ShortString {
        uint256 length;
        bytes32 data;
    }

    /// @dev Length of the "version string"
    uint256 private immutable _length;
    /// @dev Bytes representation of the "version string".
    /// Strings with length over 32 are not supported!
    bytes32 private immutable _data;

    constructor(string memory version_) {
        _length = bytes(version_).length;
        if (_length > 32) revert IncorrectVersionLength();
        // bytes32 is left-aligned => this will store the byte representation of the string
        // with the trailing zeroes to complete the 32-byte word
        _data = bytes32(bytes(version_));
    }

    function version() external view returns (string memory versionString) {
        // Load the immutable values to form the version string
        _ShortString memory str = _ShortString(_length, _data);
        // The only way to do this cast is doing some dirty assembly
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            versionString := str
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Number} from "./Number.sol";

/// GasData in encoded data with "basic information about gas prices" for some chain.
type GasData is uint96;

using GasDataLib for GasData global;

/// ChainGas is encoded data with given chain's "basic information about gas prices".
type ChainGas is uint128;

using GasDataLib for ChainGas global;

/// Library for encoding and decoding GasData and ChainGas structs.
/// # GasData
/// `GasData` is a struct to store the "basic information about gas prices", that could
/// be later used to approximate the cost of a message execution, and thus derive the
/// minimal tip values for sending a message to the chain.
/// > - `GasData` is supposed to be cached by `GasOracle` contract, allowing to store the
/// > approximates instead of the exact values, and thus save on storage costs.
/// > - For instance, if `GasOracle` only updates the values on +- 10% change, having an
/// > 0.4% error on the approximates would be acceptable.
/// `GasData` is supposed to be included in the Origin's state, which are synced across
/// chains using Agent-signed snapshots and attestations.
/// ## GasData stack layout (from highest bits to lowest)
///
/// | Position   | Field        | Type   | Bytes | Description                                         |
/// | ---------- | ------------ | ------ | ----- | --------------------------------------------------- |
/// | (012..010] | gasPrice     | uint16 | 2     | Gas price for the chain (in Wei per gas unit)       |
/// | (010..008] | dataPrice    | uint16 | 2     | Calldata price (in Wei per byte of content)         |
/// | (008..006] | execBuffer   | uint16 | 2     | Tx fee safety buffer for message execution (in Wei) |
/// | (006..004] | amortAttCost | uint16 | 2     | Amortized cost for attestation submission (in Wei)  |
/// | (004..002] | etherPrice   | uint16 | 2     | Chain's Ether Price / Mainnet Ether Price (in BWAD) |
/// | (002..000] | markup       | uint16 | 2     | Markup for the message execution (in BWAD)          |
/// > See Number.sol for more details on `Number` type and BWAD (binary WAD) math.
///
/// ## ChainGas stack layout (from highest bits to lowest)
///
/// | Position   | Field   | Type   | Bytes | Description      |
/// | ---------- | ------- | ------ | ----- | ---------------- |
/// | (016..004] | gasData | uint96 | 12    | Chain's gas data |
/// | (004..000] | domain  | uint32 | 4     | Chain's domain   |
library GasDataLib {
    /// @dev Amount of bits to shift to gasPrice field
    uint96 private constant SHIFT_GAS_PRICE = 10 * 8;
    /// @dev Amount of bits to shift to dataPrice field
    uint96 private constant SHIFT_DATA_PRICE = 8 * 8;
    /// @dev Amount of bits to shift to execBuffer field
    uint96 private constant SHIFT_EXEC_BUFFER = 6 * 8;
    /// @dev Amount of bits to shift to amortAttCost field
    uint96 private constant SHIFT_AMORT_ATT_COST = 4 * 8;
    /// @dev Amount of bits to shift to etherPrice field
    uint96 private constant SHIFT_ETHER_PRICE = 2 * 8;

    /// @dev Amount of bits to shift to gasData field
    uint128 private constant SHIFT_GAS_DATA = 4 * 8;

    // ═════════════════════════════════════════════════ GAS DATA ══════════════════════════════════════════════════════

    /// @notice Returns an encoded GasData struct with the given fields.
    /// @param gasPrice_        Gas price for the chain (in Wei per gas unit)
    /// @param dataPrice_       Calldata price (in Wei per byte of content)
    /// @param execBuffer_      Tx fee safety buffer for message execution (in Wei)
    /// @param amortAttCost_    Amortized cost for attestation submission (in Wei)
    /// @param etherPrice_      Ratio of Chain's Ether Price / Mainnet Ether Price (in BWAD)
    /// @param markup_          Markup for the message execution (in BWAD)
    function encodeGasData(
        Number gasPrice_,
        Number dataPrice_,
        Number execBuffer_,
        Number amortAttCost_,
        Number etherPrice_,
        Number markup_
    ) internal pure returns (GasData) {
        // forgefmt: disable-next-item
        return GasData.wrap(
            uint96(Number.unwrap(gasPrice_)) << SHIFT_GAS_PRICE |
            uint96(Number.unwrap(dataPrice_)) << SHIFT_DATA_PRICE |
            uint96(Number.unwrap(execBuffer_)) << SHIFT_EXEC_BUFFER |
            uint96(Number.unwrap(amortAttCost_)) << SHIFT_AMORT_ATT_COST |
            uint96(Number.unwrap(etherPrice_)) << SHIFT_ETHER_PRICE |
            uint96(Number.unwrap(markup_))
        );
    }

    /// @notice Wraps padded uint256 value into GasData struct.
    function wrapGasData(uint256 paddedGasData) internal pure returns (GasData) {
        return GasData.wrap(uint96(paddedGasData));
    }

    /// @notice Returns the gas price, in Wei per gas unit.
    function gasPrice(GasData data) internal pure returns (Number) {
        // Casting to uint16 will truncate the highest bits, which is the behavior we want
        return Number.wrap(uint16(GasData.unwrap(data) >> SHIFT_GAS_PRICE));
    }

    /// @notice Returns the calldata price, in Wei per byte of content.
    function dataPrice(GasData data) internal pure returns (Number) {
        // Casting to uint16 will truncate the highest bits, which is the behavior we want
        return Number.wrap(uint16(GasData.unwrap(data) >> SHIFT_DATA_PRICE));
    }

    /// @notice Returns the tx fee safety buffer for message execution, in Wei.
    function execBuffer(GasData data) internal pure returns (Number) {
        // Casting to uint16 will truncate the highest bits, which is the behavior we want
        return Number.wrap(uint16(GasData.unwrap(data) >> SHIFT_EXEC_BUFFER));
    }

    /// @notice Returns the amortized cost for attestation submission, in Wei.
    function amortAttCost(GasData data) internal pure returns (Number) {
        // Casting to uint16 will truncate the highest bits, which is the behavior we want
        return Number.wrap(uint16(GasData.unwrap(data) >> SHIFT_AMORT_ATT_COST));
    }

    /// @notice Returns the ratio of Chain's Ether Price / Mainnet Ether Price, in BWAD math.
    function etherPrice(GasData data) internal pure returns (Number) {
        // Casting to uint16 will truncate the highest bits, which is the behavior we want
        return Number.wrap(uint16(GasData.unwrap(data) >> SHIFT_ETHER_PRICE));
    }

    /// @notice Returns the markup for the message execution, in BWAD math.
    function markup(GasData data) internal pure returns (Number) {
        // Casting to uint16 will truncate the highest bits, which is the behavior we want
        return Number.wrap(uint16(GasData.unwrap(data)));
    }

    // ════════════════════════════════════════════════ CHAIN DATA ═════════════════════════════════════════════════════

    /// @notice Returns an encoded ChainGas struct with the given fields.
    /// @param gasData_ Chain's gas data
    /// @param domain_  Chain's domain
    function encodeChainGas(GasData gasData_, uint32 domain_) internal pure returns (ChainGas) {
        return ChainGas.wrap(uint128(GasData.unwrap(gasData_)) << SHIFT_GAS_DATA | uint128(domain_));
    }

    /// @notice Wraps padded uint256 value into ChainGas struct.
    function wrapChainGas(uint256 paddedChainGas) internal pure returns (ChainGas) {
        return ChainGas.wrap(uint128(paddedChainGas));
    }

    /// @notice Returns the chain's gas data.
    function gasData(ChainGas data) internal pure returns (GasData) {
        // Casting to uint96 will truncate the highest bits, which is the behavior we want
        return GasData.wrap(uint96(ChainGas.unwrap(data) >> SHIFT_GAS_DATA));
    }

    /// @notice Returns the chain's domain.
    function domain(ChainGas data) internal pure returns (uint32) {
        // Casting to uint32 will truncate the highest bits, which is the behavior we want
        return uint32(ChainGas.unwrap(data));
    }

    /// @notice Returns the hash for the list of ChainGas structs.
    function snapGasHash(ChainGas[] memory snapGas) internal pure returns (bytes32 snapGasHash_) {
        // Use assembly to calculate the hash of the array without copying it
        // ChainGas takes a single word of storage, thus ChainGas[] is stored in the following way:
        // 0x00: length of the array, in words
        // 0x20: first ChainGas struct
        // 0x40: second ChainGas struct
        // And so on...
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Find the location where the array data starts, we add 0x20 to skip the length field
            let loc := add(snapGas, 0x20)
            // Load the length of the array (in words).
            // Shifting left 5 bits is equivalent to multiplying by 32: this converts from words to bytes.
            let len := shl(5, mload(snapGas))
            // Calculate the hash of the array
            snapGasHash_ := keccak256(loc, len)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// Number is a compact representation of uint256, that is fit into 16 bits
/// with the maximum relative error under 0.4%.
type Number is uint16;

using NumberLib for Number global;

/// # Number
/// Library for compact representation of uint256 numbers.
/// - Number is stored using mantissa and exponent, each occupying 8 bits.
/// - Numbers under 2**8 are stored as `mantissa` with `exponent = 0xFF`.
/// - Numbers at least 2**8 are approximated as `(256 + mantissa) << exponent`
/// > - `0 <= mantissa < 256`
/// > - `0 <= exponent <= 247` (`256 * 2**248` doesn't fit into uint256)
/// # Number stack layout (from highest bits to lowest)
///
/// | Position   | Field    | Type  | Bytes |
/// | ---------- | -------- | ----- | ----- |
/// | (002..001] | mantissa | uint8 | 1     |
/// | (001..000] | exponent | uint8 | 1     |

library NumberLib {
    /// @dev Amount of bits to shift to mantissa field
    uint16 private constant SHIFT_MANTISSA = 8;

    /// @notice For bwad math (binary wad) we use 2**64 as "wad" unit.
    /// @dev We are using not using 10**18 as wad, because it is not stored precisely in NumberLib.
    uint256 internal constant BWAD_SHIFT = 64;
    uint256 internal constant BWAD = 1 << BWAD_SHIFT;
    /// @notice ~0.1% in bwad units.
    uint256 internal constant PER_MILLE_SHIFT = BWAD_SHIFT - 10;
    uint256 internal constant PER_MILLE = 1 << PER_MILLE_SHIFT;

    /// @notice Compresses uint256 number into 16 bits.
    function compress(uint256 value) internal pure returns (Number) {
        // Find `msb` such as `2**msb <= value < 2**(msb + 1)`
        uint256 msb = mostSignificantBit(value);
        // We want to preserve 9 bits of precision.
        // The highest bit is always 1, so we can skip it.
        // The remaining 8 highest bits are stored as mantissa.
        if (msb < 8) {
            // Value is less than 2**8, so we can use value as mantissa with "-1" exponent.
            return _encode(uint8(value), 0xFF);
        } else {
            // We use `msb - 8` as exponent otherwise. Note that `exponent >= 0`.
            unchecked {
                uint256 exponent = msb - 8;
                // Shifting right by `msb-8` bits will shift the "remaining 8 highest bits" into the 8 lowest bits.
                // uint8() will truncate the highest bit.
                return _encode(uint8(value >> exponent), uint8(exponent));
            }
        }
    }

    /// @notice Decompresses 16 bits number into uint256.
    /// @dev The outcome is an approximation of the original number: `(value - value / 256) < number <= value`.
    function decompress(Number number) internal pure returns (uint256 value) {
        // Isolate 8 highest bits as the mantissa.
        uint256 mantissa = Number.unwrap(number) >> SHIFT_MANTISSA;
        // This will truncate the highest bits, leaving only the exponent.
        uint256 exponent = uint8(Number.unwrap(number));
        if (exponent == 0xFF) {
            return mantissa;
        } else {
            unchecked {
                return (256 + mantissa) << (exponent);
            }
        }
    }

    /// @dev Returns the most significant bit of `x`
    /// https://solidity-by-example.org/bitwise/
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        // To find `msb` we determine it bit by bit, starting from the highest one.
        // `0 <= msb <= 255`, so we start from the highest bit, 1<<7 == 128.
        // If `x` is at least 2**128, then the highest bit of `x` is at least 128.
        // solhint-disable no-inline-assembly
        assembly {
            // `f` is set to 1<<7 if `x >= 2**128` and to 0 otherwise.
            let f := shl(7, gt(x, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            // If `x >= 2**128` then set `msb` highest bit to 1 and shift `x` right by 128.
            // Otherwise, `msb` remains 0 and `x` remains unchanged.
            x := shr(f, x)
            msb := or(msb, f)
        }
        // `x` is now at most 2**128 - 1. Continue the same way, the next highest bit is 1<<6 == 64.
        assembly {
            // `f` is set to 1<<6 if `x >= 2**64` and to 0 otherwise.
            let f := shl(6, gt(x, 0xFFFFFFFFFFFFFFFF))
            x := shr(f, x)
            msb := or(msb, f)
        }
        assembly {
            // `f` is set to 1<<5 if `x >= 2**32` and to 0 otherwise.
            let f := shl(5, gt(x, 0xFFFFFFFF))
            x := shr(f, x)
            msb := or(msb, f)
        }
        assembly {
            // `f` is set to 1<<4 if `x >= 2**16` and to 0 otherwise.
            let f := shl(4, gt(x, 0xFFFF))
            x := shr(f, x)
            msb := or(msb, f)
        }
        assembly {
            // `f` is set to 1<<3 if `x >= 2**8` and to 0 otherwise.
            let f := shl(3, gt(x, 0xFF))
            x := shr(f, x)
            msb := or(msb, f)
        }
        assembly {
            // `f` is set to 1<<2 if `x >= 2**4` and to 0 otherwise.
            let f := shl(2, gt(x, 0xF))
            x := shr(f, x)
            msb := or(msb, f)
        }
        assembly {
            // `f` is set to 1<<1 if `x >= 2**2` and to 0 otherwise.
            let f := shl(1, gt(x, 0x3))
            x := shr(f, x)
            msb := or(msb, f)
        }
        assembly {
            // `f` is set to 1 if `x >= 2**1` and to 0 otherwise.
            let f := gt(x, 0x1)
            msb := or(msb, f)
        }
    }

    /// @dev Wraps (mantissa, exponent) pair into Number.
    function _encode(uint8 mantissa, uint8 exponent) private pure returns (Number) {
        return Number.wrap(uint16(mantissa) << SHIFT_MANTISSA | uint16(exponent));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}