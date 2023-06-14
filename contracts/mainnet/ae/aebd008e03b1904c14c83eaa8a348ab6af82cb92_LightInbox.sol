// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// ══════════════════════════════ LIBRARY IMPORTS ══════════════════════════════
import {Attestation, AttestationLib} from "../libs/memory/Attestation.sol";
import {SYNAPSE_DOMAIN} from "../libs/Constants.sol";
import {IncorrectDataHash, SynapseDomainForbidden} from "../libs/Errors.sol";
import {ChainGas, GasDataLib} from "../libs/stack/GasData.sol";
import {AgentStatus} from "../libs/Structures.sol";
// ═════════════════════════════ INTERNAL IMPORTS ══════════════════════════════
import {StatementInbox} from "./StatementInbox.sol";
import {MessagingBase} from "../base/MessagingBase.sol";
import {IAgentManager} from "../interfaces/IAgentManager.sol";
import {InterfaceDestination} from "../interfaces/InterfaceDestination.sol";
import {InterfaceLightInbox} from "../interfaces/InterfaceLightInbox.sol";

/// @notice `LightInbox` is the child of `StatementInbox` contract, that is used chains other than the Synapse Chain.
/// In addition to the functionality of `StatementInbox`, it also:
/// - Accepts Notary Attestations and passes them to the `Destination` contract.
/// - Accepts Attestation Reports and initiates a dispute between the Notary and the Guard.
contract LightInbox is StatementInbox, InterfaceLightInbox {
    using AttestationLib for bytes;

    // ═════════════════════════════════════════ CONSTRUCTOR & INITIALIZER ═════════════════════════════════════════════

    constructor(uint32 domain) MessagingBase("0.0.3", domain) {
        if (domain == SYNAPSE_DOMAIN) revert SynapseDomainForbidden();
    }

    /// @notice Initializes `LightInbox` contract:
    /// - Sets `msg.sender` as the owner of the contract
    /// - Sets `agentManager`, `origin` and `destination` addresses
    function initialize(address agentManager_, address origin_, address destination_) external initializer {
        __StatementInbox_init(agentManager_, origin_, destination_);
    }

    // ══════════════════════════════════════════ SUBMIT AGENT STATEMENTS ══════════════════════════════════════════════

    /// @inheritdoc InterfaceLightInbox
    function submitAttestation(
        bytes memory attPayload,
        bytes memory attSignature,
        bytes32 agentRoot_,
        uint256[] memory snapGas_
    ) external returns (bool wasAccepted) {
        // This will revert if payload is not an attestation
        Attestation att = attPayload.castToAttestation();
        // This will revert if signer is not an known Notary
        (AgentStatus memory status, address notary) = _verifyAttestation(att, attSignature);
        // Check that Notary is active
        status.verifyActive();
        // Check if Notary is active on this chain
        _verifyNotaryDomain(status.domain);
        // Cast uint256[] to ChainGas[] using assembly. This prevents us from doing unnecessary copies.
        // Note that this does NOT clear the highest bits, but it's ok as the dirty highest bits
        // will lead to hash mismatch in snapGasHash() and thus to attestation rejection.
        ChainGas[] memory snapGas;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            snapGas := snapGas_
        }
        // Check that hash of provided data matches the attestation's dataHash
        if (
            att.dataHash()
                != AttestationLib.dataHash({agentRoot_: agentRoot_, snapGasHash_: GasDataLib.snapGasHash(snapGas)})
        ) {
            revert IncorrectDataHash();
        }
        // Store Notary signature for the attestation
        uint256 sigIndex = _saveSignature(attSignature);
        // This will revert if Notary is in Dispute
        wasAccepted = InterfaceDestination(destination).acceptAttestation({
            notaryIndex: status.index,
            sigIndex: sigIndex,
            attPayload: attPayload,
            agentRoot: agentRoot_,
            snapGas: snapGas
        });
        if (wasAccepted) {
            emit AttestationAccepted(status.domain, notary, attPayload, attSignature);
        }
    }

    /// @inheritdoc InterfaceLightInbox
    function submitAttestationReport(bytes memory attPayload, bytes memory arSignature, bytes memory attSignature)
        external
        returns (bool wasAccepted)
    {
        // This will revert if payload is not an attestation
        Attestation att = attPayload.castToAttestation();
        // This will revert if the report signer is not a known Guard
        (AgentStatus memory guardStatus,) = _verifyAttestationReport(att, arSignature);
        // Check that Guard is active
        guardStatus.verifyActive();
        // This will revert if attestation signer is not a known Notary
        (AgentStatus memory notaryStatus,) = _verifyAttestation(att, attSignature);
        // Notary needs to be Active/Unstaking
        notaryStatus.verifyActiveUnstaking();
        // Check if Notary is active on this chain
        _verifyNotaryDomain(notaryStatus.domain);
        _saveReport(attPayload, arSignature);
        // This will revert if either actor is already in dispute
        IAgentManager(agentManager).openDispute(guardStatus.index, notaryStatus.index);
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {MemView, MemViewLib} from "./MemView.sol";
import {ATTESTATION_LENGTH, ATTESTATION_VALID_SALT, ATTESTATION_INVALID_SALT} from "../Constants.sol";
import {UnformattedAttestation} from "../Errors.sol";

/// Attestation is a memory view over a formatted attestation payload.
type Attestation is uint256;

using AttestationLib for Attestation global;

/// # Attestation
/// Attestation structure represents the "Snapshot Merkle Tree" created from
/// every Notary snapshot accepted by the Summit contract. Attestation includes"
/// the root of the "Snapshot Merkle Tree", as well as additional metadata.
///
/// ## Steps for creation of "Snapshot Merkle Tree":
/// 1. The list of hashes is composed for states in the Notary snapshot.
/// 2. The list is padded with zero values until its length is 2**SNAPSHOT_TREE_HEIGHT.
/// 3. Values from the list are used as leafs and the merkle tree is constructed.
///
/// ## Differences between a State and Attestation
/// Similar to Origin, every derived Notary's "Snapshot Merkle Root" is saved in Summit contract.
/// The main difference is that Origin contract itself is keeping track of an incremental merkle tree,
/// by inserting the hash of the sent message and calculating the new "Origin Merkle Root".
/// While Summit relies on Guards and Notaries to provide snapshot data, which is used to calculate the
/// "Snapshot Merkle Root".
///
/// - Origin's State is "state of Origin Merkle Tree after N-th message was sent".
/// - Summit's Attestation is "data for the N-th accepted Notary Snapshot" + "agent merkle root at the
/// time snapshot was submitted" + "attestation metadata".
///
/// ## Attestation validity
/// - Attestation is considered "valid" in Summit contract, if it matches the N-th (nonce)
/// snapshot submitted by Notaries, as well as the historical agent merkle root.
/// - Attestation is considered "valid" in Origin contract, if its underlying Snapshot is "valid".
///
/// - This means that a snapshot could be "valid" in Summit contract and "invalid" in Origin, if the underlying
/// snapshot is invalid (i.e. one of the states in the list is invalid).
/// - The opposite could also be true. If a perfectly valid snapshot was never submitted to Summit, its attestation
/// would be valid in Origin, but invalid in Summit (it was never accepted, so the metadata would be incorrect).
///
/// - Attestation is considered "globally valid", if it is valid in the Summit and all the Origin contracts.
/// # Memory layout of Attestation fields
///
/// | Position   | Field       | Type    | Bytes | Description                                                    |
/// | ---------- | ----------- | ------- | ----- | -------------------------------------------------------------- |
/// | [000..032) | snapRoot    | bytes32 | 32    | Root for "Snapshot Merkle Tree" created from a Notary snapshot |
/// | [032..064) | dataHash    | bytes32 | 32    | Agent Root and SnapGasHash combined into a single hash         |
/// | [064..068) | nonce       | uint32  | 4     | Total amount of all accepted Notary snapshots                  |
/// | [068..073) | blockNumber | uint40  | 5     | Block when this Notary snapshot was accepted in Summit         |
/// | [073..078) | timestamp   | uint40  | 5     | Time when this Notary snapshot was accepted in Summit          |
///
/// @dev Attestation could be signed by a Notary and submitted to `Destination` in order to use if for proving
/// messages coming from origin chains that the initial snapshot refers to.
library AttestationLib {
    using MemViewLib for bytes;

    // TODO: compress three hashes into one?

    /// @dev The variables below are not supposed to be used outside of the library directly.
    uint256 private constant OFFSET_SNAP_ROOT = 0;
    uint256 private constant OFFSET_DATA_HASH = 32;
    uint256 private constant OFFSET_NONCE = 64;
    uint256 private constant OFFSET_BLOCK_NUMBER = 68;
    uint256 private constant OFFSET_TIMESTAMP = 73;

    // ════════════════════════════════════════════════ ATTESTATION ════════════════════════════════════════════════════

    /**
     * @notice Returns a formatted Attestation payload with provided fields.
     * @param snapRoot_     Snapshot merkle tree's root
     * @param dataHash_     Agent Root and SnapGasHash combined into a single hash
     * @param nonce_        Attestation Nonce
     * @param blockNumber_  Block number when attestation was created in Summit
     * @param timestamp_    Block timestamp when attestation was created in Summit
     * @return Formatted attestation
     */
    function formatAttestation(
        bytes32 snapRoot_,
        bytes32 dataHash_,
        uint32 nonce_,
        uint40 blockNumber_,
        uint40 timestamp_
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(snapRoot_, dataHash_, nonce_, blockNumber_, timestamp_);
    }

    /**
     * @notice Returns an Attestation view over the given payload.
     * @dev Will revert if the payload is not an attestation.
     */
    function castToAttestation(bytes memory payload) internal pure returns (Attestation) {
        return castToAttestation(payload.ref());
    }

    /**
     * @notice Casts a memory view to an Attestation view.
     * @dev Will revert if the memory view is not over an attestation.
     */
    function castToAttestation(MemView memView) internal pure returns (Attestation) {
        if (!isAttestation(memView)) revert UnformattedAttestation();
        return Attestation.wrap(MemView.unwrap(memView));
    }

    /// @notice Checks that a payload is a formatted Attestation.
    function isAttestation(MemView memView) internal pure returns (bool) {
        return memView.len() == ATTESTATION_LENGTH;
    }

    /// @notice Returns the hash of an Attestation, that could be later signed by a Notary to signal
    /// that the attestation is valid.
    function hashValid(Attestation att) internal pure returns (bytes32) {
        // The final hash to sign is keccak(attestationSalt, keccak(attestation))
        return att.unwrap().keccakSalted(ATTESTATION_VALID_SALT);
    }

    /// @notice Returns the hash of an Attestation, that could be later signed by a Guard to signal
    /// that the attestation is invalid.
    function hashInvalid(Attestation att) internal pure returns (bytes32) {
        // The final hash to sign is keccak(attestationInvalidSalt, keccak(attestation))
        return att.unwrap().keccakSalted(ATTESTATION_INVALID_SALT);
    }

    /// @notice Convenience shortcut for unwrapping a view.
    function unwrap(Attestation att) internal pure returns (MemView) {
        return MemView.wrap(Attestation.unwrap(att));
    }

    // ════════════════════════════════════════════ ATTESTATION SLICING ════════════════════════════════════════════════

    /// @notice Returns root of the Snapshot merkle tree created in the Summit contract.
    function snapRoot(Attestation att) internal pure returns (bytes32) {
        return att.unwrap().index({index_: OFFSET_SNAP_ROOT, bytes_: 32});
    }

    /// @notice Returns hash of the Agent Root and SnapGasHash combined into a single hash.
    function dataHash(Attestation att) internal pure returns (bytes32) {
        return att.unwrap().index({index_: OFFSET_DATA_HASH, bytes_: 32});
    }

    /// @notice Returns hash of the Agent Root and SnapGasHash combined into a single hash.
    function dataHash(bytes32 agentRoot_, bytes32 snapGasHash_) internal pure returns (bytes32) {
        return keccak256(bytes.concat(agentRoot_, snapGasHash_));
    }

    /// @notice Returns nonce of Summit contract at the time, when attestation was created.
    function nonce(Attestation att) internal pure returns (uint32) {
        return uint32(att.unwrap().indexUint({index_: OFFSET_NONCE, bytes_: 4}));
    }

    /// @notice Returns a block number when attestation was created in Summit.
    function blockNumber(Attestation att) internal pure returns (uint40) {
        return uint40(att.unwrap().indexUint({index_: OFFSET_BLOCK_NUMBER, bytes_: 5}));
    }

    /// @notice Returns a block timestamp when attestation was created in Summit.
    /// @dev This is the timestamp according to the Synapse Chain.
    function timestamp(Attestation att) internal pure returns (uint40) {
        return uint40(att.unwrap().indexUint({index_: OFFSET_TIMESTAMP, bytes_: 5}));
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
import {Attestation, AttestationLib} from "../libs/memory/Attestation.sol";
import {SYNAPSE_DOMAIN} from "../libs/Constants.sol";
import {
    AgentNotGuard,
    AgentNotNotary,
    IncorrectAgentDomain,
    IncorrectSnapshotProof,
    IncorrectSnapshotRoot,
    IncorrectState,
    IndexOutOfRange
} from "../libs/Errors.sol";
import {Receipt, ReceiptLib} from "../libs/memory/Receipt.sol";
import {Snapshot, SnapshotLib} from "../libs/memory/Snapshot.sol";
import {State, StateLib} from "../libs/memory/State.sol";
import {AgentStatus} from "../libs/Structures.sol";
// ═════════════════════════════ INTERNAL IMPORTS ══════════════════════════════
import {MessagingBase} from "../base/MessagingBase.sol";
import {StatementInboxEvents} from "../events/StatementInboxEvents.sol";
import {IAgentManager} from "../interfaces/IAgentManager.sol";
import {IExecutionHub} from "../interfaces/IExecutionHub.sol";
import {IStateHub} from "../interfaces/IStateHub.sol";
import {IStatementInbox} from "../interfaces/IStatementInbox.sol";
// ═════════════════════════════ EXTERNAL IMPORTS ══════════════════════════════
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @notice `StatementInbox` is the entry point for all agent-signed statements. It verifies the
/// agent signatures, and passes the unsigned statements to the contract to consume it via `acceptX` functions. Is is
/// also used to verify the agent-signed statements and initiate the agent slashing, should the statement be invalid.
/// `StatementInbox` is responsible for the following:
/// - Accepting State and Receipt Reports to initiate a dispute between Guard and Notary.
/// - Storing all the Guard Reports with the Guard signature leading to a dispute.
/// - Verifying State/State Reports referencing the local chain and slashing the signer if statement is invalid.
/// - Verifying Receipt/Receipt Reports referencing the local chain and slashing the signer if statement is invalid.
abstract contract StatementInbox is MessagingBase, StatementInboxEvents, IStatementInbox {
    using AttestationLib for bytes;
    using ReceiptLib for bytes;
    using StateLib for bytes;
    using SnapshotLib for bytes;

    struct StoredReport {
        uint256 sigIndex;
        bytes statementPayload;
    }

    // ══════════════════════════════════════════════════ STORAGE ══════════════════════════════════════════════════════

    address public agentManager;
    address public origin;
    address public destination;

    // TODO: optimize this
    bytes[] internal _storedSignatures;
    StoredReport[] internal _storedReports;

    /// @dev gap for upgrade safety
    uint256[45] private __GAP; // solhint-disable-line var-name-mixedcase

    // ════════════════════════════════════════════════ INITIALIZER ════════════════════════════════════════════════════

    /// @dev Initializes the contract:
    /// - Sets up `msg.sender` as the owner of the contract.
    /// - Sets up `agentManager`, `origin`, and `destination`.
    // solhint-disable-next-line func-name-mixedcase
    function __StatementInbox_init(address agentManager_, address origin_, address destination_)
        internal
        onlyInitializing
    {
        agentManager = agentManager_;
        origin = origin_;
        destination = destination_;
        __Ownable_init();
    }

    // ══════════════════════════════════════════ SUBMIT AGENT STATEMENTS ══════════════════════════════════════════════

    /// @inheritdoc IStatementInbox
    // solhint-disable-next-line ordering
    function submitStateReportWithSnapshot(
        uint256 stateIndex,
        bytes memory srSignature,
        bytes memory snapPayload,
        bytes memory snapSignature
    ) external returns (bool wasAccepted) {
        // This will revert if payload is not a snapshot
        Snapshot snapshot = snapPayload.castToSnapshot();
        // This will revert if the snapshot signer is not a known Notary
        (AgentStatus memory notaryStatus,) =
            _verifySnapshot({snapshot: snapshot, snapSignature: snapSignature, verifyNotary: true});
        // Notary needs to be Active/Unstaking
        notaryStatus.verifyActiveUnstaking();
        // Check if Notary is active on this chain
        _verifyNotaryDomain(notaryStatus.domain);
        // This will revert if state index is out of range
        State state = snapshot.state(stateIndex);
        // This will revert if the report signer is not an known Guard
        (AgentStatus memory guardStatus,) = _verifyStateReport(state, srSignature);
        // Check that Guard is active
        guardStatus.verifyActive();
        _saveReport(state.unwrap().clone(), srSignature);
        // This will revert if either actor is already in dispute
        IAgentManager(agentManager).openDispute(guardStatus.index, notaryStatus.index);
        return true;
    }

    /// @inheritdoc IStatementInbox
    function submitStateReportWithAttestation(
        uint256 stateIndex,
        bytes memory srSignature,
        bytes memory snapPayload,
        bytes memory attPayload,
        bytes memory attSignature
    ) external returns (bool wasAccepted) {
        // This will revert if payload is not a snapshot
        Snapshot snapshot = snapPayload.castToSnapshot();
        // This will revert if state index is out of range
        State state = snapshot.state(stateIndex);
        // This will revert if the report signer is not an known Guard
        (AgentStatus memory guardStatus,) = _verifyStateReport(state, srSignature);
        // Check that Guard is active
        guardStatus.verifyActive();
        // This will revert if payload is not an attestation
        Attestation att = attPayload.castToAttestation();
        // This will revert if signer is not an known Notary
        (AgentStatus memory notaryStatus,) = _verifyAttestation(att, attSignature);
        // Notary needs to be Active/Unstaking
        notaryStatus.verifyActiveUnstaking();
        // Check if Notary is active on this chain
        _verifyNotaryDomain(notaryStatus.domain);
        if (snapshot.calculateRoot() != att.snapRoot()) revert IncorrectSnapshotRoot();
        _saveReport(state.unwrap().clone(), srSignature);
        // This will revert if either actor is already in dispute
        IAgentManager(agentManager).openDispute(guardStatus.index, notaryStatus.index);
        return true;
    }

    /// @inheritdoc IStatementInbox
    function submitStateReportWithSnapshotProof(
        uint256 stateIndex,
        bytes memory statePayload,
        bytes memory srSignature,
        bytes32[] memory snapProof,
        bytes memory attPayload,
        bytes memory attSignature
    ) external returns (bool wasAccepted) {
        // This will revert if payload is not a state
        State state = statePayload.castToState();
        // This will revert if the report signer is not an known Guard
        (AgentStatus memory guardStatus,) = _verifyStateReport(state, srSignature);
        // Check that Guard is active
        guardStatus.verifyActive();
        // This will revert if payload is not an attestation
        Attestation att = attPayload.castToAttestation();
        // This will revert if signer is not a known Notary
        (AgentStatus memory notaryStatus,) = _verifyAttestation(att, attSignature);
        // Notary needs to be Active/Unstaking
        notaryStatus.verifyActiveUnstaking();
        // Check if Notary is active on this chain
        _verifyNotaryDomain(notaryStatus.domain);
        // This will revert if any of these is true:
        //  - Attestation root is not equal to Merkle Root derived from State and Snapshot Proof.
        //  - Snapshot Proof's first element does not match the State metadata.
        //  - Snapshot Proof length exceeds Snapshot tree Height.
        //  - State index is out of range.
        _verifySnapshotMerkle(att, stateIndex, state, snapProof);
        _saveReport(statePayload, srSignature);
        // This will revert if either actor is already in dispute
        IAgentManager(agentManager).openDispute(guardStatus.index, notaryStatus.index);
        return true;
    }

    // ══════════════════════════════════════════ VERIFY AGENT STATEMENTS ══════════════════════════════════════════════

    /// @inheritdoc IStatementInbox
    function verifyReceipt(bytes memory rcptPayload, bytes memory rcptSignature)
        external
        returns (bool isValidReceipt)
    {
        // This will revert if payload is not a receipt
        Receipt rcpt = rcptPayload.castToReceipt();
        // This will revert if the attestation signer is not a known Notary
        (AgentStatus memory status, address notary) = _verifyReceipt(rcpt, rcptSignature);
        // Notary needs to be Active/Unstaking
        status.verifyActiveUnstaking();
        isValidReceipt = IExecutionHub(destination).isValidReceipt(rcptPayload);
        if (!isValidReceipt) {
            emit InvalidReceipt(rcptPayload, rcptSignature);
            IAgentManager(agentManager).slashAgent(status.domain, notary, msg.sender);
        }
    }

    /// @inheritdoc IStatementInbox
    function verifyReceiptReport(bytes memory rcptPayload, bytes memory rrSignature)
        external
        returns (bool isValidReport)
    {
        // This will revert if payload is not a receipt
        Receipt rcpt = rcptPayload.castToReceipt();
        // This will revert if the report signer is not a known Guard
        (AgentStatus memory status, address guard) = _verifyReceiptReport(rcpt, rrSignature);
        // Guard needs to be Active/Unstaking
        status.verifyActiveUnstaking();
        // Report is valid IF AND ONLY IF the reported receipt in invalid
        isValidReport = !IExecutionHub(destination).isValidReceipt(rcptPayload);
        if (!isValidReport) {
            emit InvalidReceiptReport(rcptPayload, rrSignature);
            IAgentManager(agentManager).slashAgent(status.domain, guard, msg.sender);
        }
    }

    /// @inheritdoc IStatementInbox
    function verifyStateWithAttestation(
        uint256 stateIndex,
        bytes memory snapPayload,
        bytes memory attPayload,
        bytes memory attSignature
    ) external returns (bool isValidState) {
        // This will revert if payload is not an attestation
        Attestation att = attPayload.castToAttestation();
        // This will revert if the attestation signer is not a known Notary
        (AgentStatus memory status, address notary) = _verifyAttestation(att, attSignature);
        // Notary needs to be Active/Unstaking
        status.verifyActiveUnstaking();
        // This will revert if payload is not a snapshot
        Snapshot snapshot = snapPayload.castToSnapshot();
        if (snapshot.calculateRoot() != att.snapRoot()) revert IncorrectSnapshotRoot();
        // This will revert if state does not refer to this chain
        bytes memory statePayload = snapshot.state(stateIndex).unwrap().clone();
        isValidState = IStateHub(origin).isValidState(statePayload);
        if (!isValidState) {
            emit InvalidStateWithAttestation(stateIndex, statePayload, attPayload, attSignature);
            IAgentManager(agentManager).slashAgent(status.domain, notary, msg.sender);
        }
    }

    /// @inheritdoc IStatementInbox
    function verifyStateWithSnapshotProof(
        uint256 stateIndex,
        bytes memory statePayload,
        bytes32[] memory snapProof,
        bytes memory attPayload,
        bytes memory attSignature
    ) external returns (bool isValidState) {
        // This will revert if payload is not an attestation
        Attestation att = attPayload.castToAttestation();
        // This will revert if the attestation signer is not a known Notary
        (AgentStatus memory status, address notary) = _verifyAttestation(att, attSignature);
        // Notary needs to be Active/Unstaking
        status.verifyActiveUnstaking();
        // This will revert if payload is not a state
        State state = statePayload.castToState();
        // This will revert if any of these is true:
        //  - Attestation root is not equal to Merkle Root derived from State and Snapshot Proof.
        //  - Snapshot Proof's first element does not match the State metadata.
        //  - Snapshot Proof length exceeds Snapshot tree Height.
        //  - State index is out of range.
        _verifySnapshotMerkle(att, stateIndex, state, snapProof);
        // This will revert if state does not refer to this chain
        isValidState = IStateHub(origin).isValidState(statePayload);
        if (!isValidState) {
            emit InvalidStateWithAttestation(stateIndex, statePayload, attPayload, attSignature);
            IAgentManager(agentManager).slashAgent(status.domain, notary, msg.sender);
        }
    }

    /// @inheritdoc IStatementInbox
    function verifyStateWithSnapshot(uint256 stateIndex, bytes memory snapPayload, bytes memory snapSignature)
        external
        returns (bool isValidState)
    {
        // This will revert if payload is not a snapshot
        Snapshot snapshot = snapPayload.castToSnapshot();
        // This will revert if the snapshot signer is not a known Guard/Notary
        (AgentStatus memory status, address agent) =
            _verifySnapshot({snapshot: snapshot, snapSignature: snapSignature, verifyNotary: false});
        // Agent needs to be Active/Unstaking
        status.verifyActiveUnstaking();
        // This will revert if state does not refer to this chain
        isValidState = IStateHub(origin).isValidState(snapshot.state(stateIndex).unwrap().clone());
        if (!isValidState) {
            emit InvalidStateWithSnapshot(stateIndex, snapPayload, snapSignature);
            IAgentManager(agentManager).slashAgent(status.domain, agent, msg.sender);
        }
    }

    /// @inheritdoc IStatementInbox
    function verifyStateReport(bytes memory statePayload, bytes memory srSignature)
        external
        returns (bool isValidReport)
    {
        // This will revert if payload is not a state
        State state = statePayload.castToState();
        // This will revert if the report signer is not a known Guard
        (AgentStatus memory status, address guard) = _verifyStateReport(state, srSignature);
        // Guard needs to be Active/Unstaking
        status.verifyActiveUnstaking();
        // Report is valid IF AND ONLY IF the reported state in invalid
        // This will revert if the reported state does not refer to this chain
        isValidReport = !IStateHub(origin).isValidState(statePayload);
        if (!isValidReport) {
            emit InvalidStateReport(statePayload, srSignature);
            IAgentManager(agentManager).slashAgent(status.domain, guard, msg.sender);
        }
    }

    // ═══════════════════════════════════════════════════ VIEWS ═══════════════════════════════════════════════════════

    /// @inheritdoc IStatementInbox
    function getReportsAmount() external view returns (uint256) {
        return _storedReports.length;
    }

    /// @inheritdoc IStatementInbox
    function getGuardReport(uint256 index)
        external
        view
        returns (bytes memory statementPayload, bytes memory reportSignature)
    {
        if (index >= _storedReports.length) revert IndexOutOfRange();
        StoredReport memory storedReport = _storedReports[index];
        statementPayload = storedReport.statementPayload;
        reportSignature = _storedSignatures[storedReport.sigIndex];
    }

    /// @inheritdoc IStatementInbox
    function getStoredSignature(uint256 index) external view returns (bytes memory) {
        return _storedSignatures[index];
    }

    // ══════════════════════════════════════════════ INTERNAL LOGIC ═══════════════════════════════════════════════════

    /// @dev Saves the statement reported by Guard as invalid and the Guard Report signature.
    function _saveReport(bytes memory statementPayload, bytes memory reportSignature) internal {
        uint256 sigIndex = _saveSignature(reportSignature);
        _storedReports.push(StoredReport(sigIndex, statementPayload));
    }

    /// @dev Saves the signature and returns its index.
    function _saveSignature(bytes memory signature) internal returns (uint256 sigIndex) {
        sigIndex = _storedSignatures.length;
        _storedSignatures.push(signature);
    }

    // ═══════════════════════════════════════════════ AGENT CHECKS ════════════════════════════════════════════════════

    /**
     * @dev Recovers a signer from a hashed message, and a EIP-191 signature for it.
     * Will revert, if the signer is not a known agent.
     * @dev Agent flag could be any of these: Active/Unstaking/Resting/Fraudulent/Slashed
     * Further checks need to be performed in a caller function.
     * @param hashedStatement   Hash of the statement that was signed by an Agent
     * @param signature         Agent signature for the hashed statement
     * @return status   Struct representing agent status:
     *                  - flag      Unknown/Active/Unstaking/Resting/Fraudulent/Slashed
     *                  - domain    Domain where agent is/was active
     *                  - index     Index of agent in the Agent Merkle Tree
     * @return agent    Agent that signed the statement
     */
    function _recoverAgent(bytes32 hashedStatement, bytes memory signature)
        internal
        view
        returns (AgentStatus memory status, address agent)
    {
        bytes32 ethSignedMsg = ECDSA.toEthSignedMessageHash(hashedStatement);
        agent = ECDSA.recover(ethSignedMsg, signature);
        status = IAgentManager(agentManager).agentStatus(agent);
        // Discard signature of unknown agents.
        // Further flag checks are supposed to be performed in a caller function.
        status.verifyKnown();
    }

    /// @dev Verifies that Notary signature is active on local domain.
    function _verifyNotaryDomain(uint32 notaryDomain) internal view {
        // Notary needs to be from the local domain (if contract is not deployed on Synapse Chain).
        // Or Notary could be from any domain (if contract is deployed on Synapse Chain).
        if (notaryDomain != localDomain && localDomain != SYNAPSE_DOMAIN) revert IncorrectAgentDomain();
    }

    // ════════════════════════════════════════ ATTESTATION RELATED CHECKS ═════════════════════════════════════════════

    /**
     * @dev Internal function to verify the signed attestation payload.
     * Reverts if any of these is true:
     *  - Attestation signer is not a known Notary.
     * @param att               Typed memory view over attestation payload
     * @param attSignature      Notary signature for the attestation
     * @return status           Struct representing agent status, see {_recoverAgent}
     * @return notary           Notary that signed the snapshot
     */
    function _verifyAttestation(Attestation att, bytes memory attSignature)
        internal
        view
        returns (AgentStatus memory status, address notary)
    {
        // This will revert if signer is not a known agent
        (status, notary) = _recoverAgent(att.hashValid(), attSignature);
        // Attestation signer needs to be a Notary, not a Guard
        if (status.domain == 0) revert AgentNotNotary();
    }

    /**
     * @dev Internal function to verify the signed attestation report payload.
     * Reverts if any of these is true:
     *  - Report signer is not a known Guard.
     * @param att               Typed memory view over attestation payload that Guard reports as invalid
     * @param arSignature       Guard signature for the "invalid attestation" report
     * @return status           Struct representing guard status, see {_recoverAgent}
     * @return guard            Guard that signed the report
     */
    function _verifyAttestationReport(Attestation att, bytes memory arSignature)
        internal
        view
        returns (AgentStatus memory status, address guard)
    {
        // This will revert if signer is not a known agent
        (status, guard) = _recoverAgent(att.hashInvalid(), arSignature);
        // Report signer needs to be a Guard, not a Notary
        if (status.domain != 0) revert AgentNotGuard();
    }

    // ══════════════════════════════════════════ RECEIPT RELATED CHECKS ═══════════════════════════════════════════════

    /**
     * @dev Internal function to verify the signed receipt payload.
     * Reverts if any of these is true:
     *  - Receipt signer is not a known Notary.
     * @param rcpt              Typed memory view over receipt payload
     * @param rcptSignature     Notary signature for the receipt
     * @return status           Struct representing agent status, see {_recoverAgent}
     * @return notary           Notary that signed the snapshot
     */
    function _verifyReceipt(Receipt rcpt, bytes memory rcptSignature)
        internal
        view
        returns (AgentStatus memory status, address notary)
    {
        // This will revert if signer is not a known agent
        (status, notary) = _recoverAgent(rcpt.hashValid(), rcptSignature);
        // Receipt signer needs to be a Notary, not a Guard
        if (status.domain == 0) revert AgentNotNotary();
    }

    /**
     * @dev Internal function to verify the signed receipt report payload.
     * Reverts if any of these is true:
     * - Report signer is not a known Guard.
     * @param rcpt              Typed memory view over receipt payload that Guard reports as invalid
     * @param rrSignature       Guard signature for the "invalid receipt" report
     * @return status           Struct representing guard status, see {_recoverAgent}
     * @return guard            Guard that signed the report
     */
    function _verifyReceiptReport(Receipt rcpt, bytes memory rrSignature)
        internal
        view
        returns (AgentStatus memory status, address guard)
    {
        // This will revert if signer is not a known agent
        (status, guard) = _recoverAgent(rcpt.hashInvalid(), rrSignature);
        // Report signer needs to be a Guard, not a Notary
        if (status.domain != 0) revert AgentNotGuard();
    }

    // ═══════════════════════════════════════ STATE/SNAPSHOT RELATED CHECKS ═══════════════════════════════════════════

    /**
     * @dev Internal function to verify the signed snapshot report payload.
     * Reverts if any of these is true:
     *  - Report signer is not a known Guard.
     * @param state             Typed memory view over state payload that Guard reports as invalid
     * @param srSignature       Guard signature for the report
     * @return status           Struct representing guard status, see {_recoverAgent}
     * @return guard            Guard that signed the report
     */
    function _verifyStateReport(State state, bytes memory srSignature)
        internal
        view
        returns (AgentStatus memory status, address guard)
    {
        // This will revert if signer is not a known agent
        (status, guard) = _recoverAgent(state.hashInvalid(), srSignature);
        // Report signer needs to be a Guard, not a Notary
        if (status.domain != 0) revert AgentNotGuard();
    }

    /**
     * @dev Internal function to verify the signed snapshot payload.
     * Reverts if any of these is true:
     *  - Snapshot signer is not a known Agent.
     *  - Snapshot signer is not a Notary (if verifyNotary is true).
     * @param snapshot          Typed memory view over snapshot payload
     * @param snapSignature     Agent signature for the snapshot
     * @param verifyNotary      If true, snapshot signer needs to be a Notary, not a Guard
     * @return status           Struct representing agent status, see {_recoverAgent}
     * @return agent            Agent that signed the snapshot
     */
    function _verifySnapshot(Snapshot snapshot, bytes memory snapSignature, bool verifyNotary)
        internal
        view
        returns (AgentStatus memory status, address agent)
    {
        // This will revert if signer is not a known agent
        (status, agent) = _recoverAgent(snapshot.hashValid(), snapSignature);
        // If requested, snapshot signer needs to be a Notary, not a Guard
        if (verifyNotary && status.domain == 0) revert AgentNotNotary();
    }

    // ═══════════════════════════════════════════ MERKLE RELATED CHECKS ═══════════════════════════════════════════════

    /**
     * @dev Internal function to verify that snapshot roots match.
     * Reverts if any of these is true:
     *  - Attestation root is not equal to Merkle Root derived from State and Snapshot Proof.
     *  - Snapshot Proof's first element does not match the State metadata.
     *  - Snapshot Proof length exceeds Snapshot tree Height.
     *  - State index is out of range.
     * @param att               Typed memory view over Attestation
     * @param stateIndex        Index of state in the snapshot
     * @param state             Typed memory view over the provided state payload
     * @param snapProof         Raw payload with snapshot data
     */
    function _verifySnapshotMerkle(Attestation att, uint256 stateIndex, State state, bytes32[] memory snapProof)
        internal
        pure
    {
        // Snapshot proof first element should match State metadata (aka "right sub-leaf")
        (, bytes32 rightSubLeaf) = state.subLeafs();
        if (snapProof[0] != rightSubLeaf) revert IncorrectSnapshotProof();
        // Reconstruct Snapshot Merkle Root using the snapshot proof
        // This will revert if:
        //  - State index is out of range.
        //  - Snapshot Proof length exceeds Snapshot tree Height.
        bytes32 snapshotRoot = SnapshotLib.proofSnapRoot(state.root(), state.origin(), snapProof, stateIndex);
        // Snapshot root should match the attestation root
        if (att.snapRoot() != snapshotRoot) revert IncorrectSnapshotRoot();
    }
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

interface InterfaceLightInbox {
    // ══════════════════════════════════════════ SUBMIT AGENT STATEMENTS ══════════════════════════════════════════════

    /**
     * @notice Accepts an attestation signed by a Notary and passes it to Destination contract to save.
     * > Attestation is created whenever a Notary-signed snapshot is saved in Summit on Synapse Chain.
     * - Saved Attestation could be later used to prove the inclusion of message in the Origin Merkle Tree.
     * - Messages coming from chains included in the Attestation's snapshot could be proven.
     * - Proof only exists for messages that were sent prior to when the Attestation's snapshot was taken.
     * > Will revert if any of these is true:
     * > - Attestation payload is not properly formatted.
     * > - Attestation signer is not an active Notary for local domain.
     * > - Attestation signer is in Dispute.
     * > - Attestation's snapshot root has been previously submitted.
     * > - Attestation's data hash doesn't match the hash of provided agentRoot and snapshot gas data.
     * @param attPayload        Raw payload with Attestation data
     * @param attSignature      Notary signature for the attestation
     * @param agentRoot         Agent Merkle Root from the Attestation
     * @param snapGas           Gas data for each chain in the snapshot
     * @return wasAccepted      Whether the Attestation was accepted
     */
    function submitAttestation(
        bytes memory attPayload,
        bytes memory attSignature,
        bytes32 agentRoot,
        uint256[] memory snapGas
    ) external returns (bool wasAccepted);

    /**
     * @notice Accepts a Guard's attestation report signature, as well as Notary signature
     * for the reported Attestation.
     * > AttestationReport is a Guard statement saying "Reported attestation is invalid".
     * - This results in an opened Dispute between the Guard and the Notary.
     * - Note: Guard could (but doesn't have to) form a AttestationReport and use attestation signature from
     * `verifyAttestation()` successful call that led to Notary being slashed in Summit on Synapse Chain.
     * > Will revert if any of these is true:
     * > - Attestation payload is not properly formatted.
     * > - Attestation Report signer is not an active Guard.
     * > - Attestation signer is not an active Notary for local domain.
     * @param attPayload        Raw payload with Attestation data that Guard reports as invalid
     * @param arSignature       Guard signature for the report
     * @param attSignature      Notary signature for the reported attestation
     * @return wasAccepted      Whether the Report was accepted (resulting in Dispute between the agents)
     */
    function submitAttestationReport(bytes memory attPayload, bytes memory arSignature, bytes memory attSignature)
        external
        returns (bool wasAccepted);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IndexedTooMuch, OccupiedMemory, PrecompileOutOfGas, UnallocatedMemory, ViewOverrun} from "../Errors.sol";

/// @dev MemView is an untyped view over a portion of memory to be used instead of `bytes memory`
type MemView is uint256;

/// @dev Attach library functions to MemView
using MemViewLib for MemView global;

/// @notice Library for operations with the memory views.
/// Forked from https://github.com/summa-tx/memview-sol with several breaking changes:
/// - The codebase is ported to Solidity 0.8
/// - Custom errors are added
/// - The runtime type checking is replaced with compile-time check provided by User-Defined Value Types
///   https://docs.soliditylang.org/en/latest/types.html#user-defined-value-types
/// - uint256 is used as the underlying type for the "memory view" instead of bytes29.
///   It is wrapped into MemView custom type in order not to be confused with actual integers.
/// - Therefore the "type" field is discarded, allowing to allocate 16 bytes for both view location and length
/// - The documentation is expanded
/// - Library functions unused by the rest of the codebase are removed
//  - Very pretty code separators are added :)
library MemViewLib {
    /// @notice Stack layout for uint256 (from highest bits to lowest)
    /// (32 .. 16]      loc     16 bytes    Memory address of underlying bytes
    /// (16 .. 00]      len     16 bytes    Length of underlying bytes

    // ═══════════════════════════════════════════ BUILDING MEMORY VIEW ════════════════════════════════════════════════

    /**
     * @notice Instantiate a new untyped memory view. This should generally not be called directly.
     * Prefer `ref` wherever possible.
     * @param loc_          The memory address
     * @param len_          The length
     * @return The new view with the specified location and length
     */
    function build(uint256 loc_, uint256 len_) internal pure returns (MemView) {
        uint256 end_ = loc_ + len_;
        // Make sure that a view is not constructed that points to unallocated memory
        // as this could be indicative of a buffer overflow attack
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            if gt(end_, mload(0x40)) { end_ := 0 }
        }
        if (end_ == 0) {
            revert UnallocatedMemory();
        }
        return _unsafeBuildUnchecked(loc_, len_);
    }

    /**
     * @notice Instantiate a memory view from a byte array.
     * @dev Note that due to Solidity memory representation, it is not possible to
     * implement a deref, as the `bytes` type stores its len in memory.
     * @param arr           The byte array
     * @return The memory view over the provided byte array
     */
    function ref(bytes memory arr) internal pure returns (MemView) {
        uint256 len_ = arr.length;
        // `bytes arr` is stored in memory in the following way
        // 1. First, uint256 arr.length is stored. That requires 32 bytes (0x20).
        // 2. Then, the array data is stored.
        uint256 loc_;
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            // We add 0x20, so that the view starts exactly where the array data starts
            loc_ := add(arr, 0x20)
        }
        return build(loc_, len_);
    }

    // ════════════════════════════════════════════ CLONING MEMORY VIEW ════════════════════════════════════════════════

    /**
     * @notice Copies the referenced memory to a new loc in memory, returning a `bytes` pointing to the new memory.
     * @param memView       The memory view
     * @return arr          The cloned byte array
     */
    function clone(MemView memView) internal view returns (bytes memory arr) {
        uint256 ptr;
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            // Load unused memory pointer
            ptr := mload(0x40)
            // This is where the byte array will be stored
            arr := ptr
        }
        unchecked {
            _unsafeCopyTo(memView, ptr + 0x20);
        }
        // `bytes arr` is stored in memory in the following way
        // 1. First, uint256 arr.length is stored. That requires 32 bytes (0x20).
        // 2. Then, the array data is stored.
        uint256 len_ = memView.len();
        uint256 footprint_ = memView.footprint();
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            // Write new unused pointer: the old value + array footprint + 32 bytes to store the length
            mstore(0x40, add(add(ptr, footprint_), 0x20))
            // Write len of new array (in bytes)
            mstore(ptr, len_)
        }
    }

    /**
     * @notice Copies all views, joins them into a new bytearray.
     * @param memViews      The memory views
     * @return arr          The new byte array with joined data behind the given views
     */
    function join(MemView[] memory memViews) internal view returns (bytes memory arr) {
        uint256 ptr;
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            // Load unused memory pointer
            ptr := mload(0x40)
            // This is where the byte array will be stored
            arr := ptr
        }
        MemView newView;
        unchecked {
            newView = _unsafeJoin(memViews, ptr + 0x20);
        }
        uint256 len_ = newView.len();
        uint256 footprint_ = newView.footprint();
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            // Write new unused pointer: the old value + array footprint + 32 bytes to store the length
            mstore(0x40, add(add(ptr, footprint_), 0x20))
            // Write len of new array (in bytes)
            mstore(ptr, len_)
        }
    }

    // ══════════════════════════════════════════ INSPECTING MEMORY VIEW ═══════════════════════════════════════════════

    /**
     * @notice Returns the memory address of the underlying bytes.
     * @param memView       The memory view
     * @return loc_         The memory address
     */
    function loc(MemView memView) internal pure returns (uint256 loc_) {
        // loc is stored in the highest 16 bytes of the underlying uint256
        return MemView.unwrap(memView) >> 128;
    }

    /**
     * @notice Returns the number of bytes of the view.
     * @param memView       The memory view
     * @return len_         The length of the view
     */
    function len(MemView memView) internal pure returns (uint256 len_) {
        // len is stored in the lowest 16 bytes of the underlying uint256
        return MemView.unwrap(memView) & type(uint128).max;
    }

    /**
     * @notice Returns the endpoint of `memView`.
     * @param memView       The memory view
     * @return end_         The endpoint of `memView`
     */
    function end(MemView memView) internal pure returns (uint256 end_) {
        // The endpoint never overflows uint128, let alone uint256, so we could use unchecked math here
        unchecked {
            return memView.loc() + memView.len();
        }
    }

    /**
     * @notice Returns the number of memory words this memory view occupies, rounded up.
     * @param memView       The memory view
     * @return words_       The number of memory words
     */
    function words(MemView memView) internal pure returns (uint256 words_) {
        // returning ceil(length / 32.0)
        unchecked {
            return (memView.len() + 31) >> 5;
        }
    }

    /**
     * @notice Returns the in-memory footprint of a fresh copy of the view.
     * @param memView       The memory view
     * @return footprint_   The in-memory footprint of a fresh copy of the view.
     */
    function footprint(MemView memView) internal pure returns (uint256 footprint_) {
        // words() * 32
        return memView.words() << 5;
    }

    // ════════════════════════════════════════════ HASHING MEMORY VIEW ════════════════════════════════════════════════

    /**
     * @notice Returns the keccak256 hash of the underlying memory
     * @param memView       The memory view
     * @return digest       The keccak256 hash of the underlying memory
     */
    function keccak(MemView memView) internal pure returns (bytes32 digest) {
        uint256 loc_ = memView.loc();
        uint256 len_ = memView.len();
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            digest := keccak256(loc_, len_)
        }
    }

    /**
     * @notice Adds a salt to the keccak256 hash of the underlying data and returns the keccak256 hash of the
     * resulting data.
     * @param memView       The memory view
     * @return digestSalted keccak256(salt, keccak256(memView))
     */
    function keccakSalted(MemView memView, bytes32 salt) internal pure returns (bytes32 digestSalted) {
        return keccak256(bytes.concat(salt, memView.keccak()));
    }

    // ════════════════════════════════════════════ SLICING MEMORY VIEW ════════════════════════════════════════════════

    /**
     * @notice Safe slicing without memory modification.
     * @param memView       The memory view
     * @param index_        The start index
     * @param len_          The length
     * @return The new view for the slice of the given length starting from the given index
     */
    function slice(MemView memView, uint256 index_, uint256 len_) internal pure returns (MemView) {
        uint256 loc_ = memView.loc();
        // Ensure it doesn't overrun the view
        if (loc_ + index_ + len_ > memView.end()) {
            revert ViewOverrun();
        }
        // Build a view starting from index with the given length
        unchecked {
            // loc_ + index_ <= memView.end()
            return build({loc_: loc_ + index_, len_: len_});
        }
    }

    /**
     * @notice Shortcut to `slice`. Gets a view representing bytes from `index` to end(memView).
     * @param memView       The memory view
     * @param index_        The start index
     * @return The new view for the slice starting from the given index until the initial view endpoint
     */
    function sliceFrom(MemView memView, uint256 index_) internal pure returns (MemView) {
        uint256 len_ = memView.len();
        // Ensure it doesn't overrun the view
        if (index_ > len_) {
            revert ViewOverrun();
        }
        // Build a view starting from index with the given length
        unchecked {
            // index_ <= len_ => memView.loc() + index_ <= memView.loc() + memView.len() == memView.end()
            return build({loc_: memView.loc() + index_, len_: len_ - index_});
        }
    }

    /**
     * @notice Shortcut to `slice`. Gets a view representing the first `len` bytes.
     * @param memView       The memory view
     * @param len_          The length
     * @return The new view for the slice of the given length starting from the initial view beginning
     */
    function prefix(MemView memView, uint256 len_) internal pure returns (MemView) {
        return memView.slice({index_: 0, len_: len_});
    }

    /**
     * @notice Shortcut to `slice`. Gets a view representing the last `len` byte.
     * @param memView       The memory view
     * @param len_          The length
     * @return The new view for the slice of the given length until the initial view endpoint
     */
    function postfix(MemView memView, uint256 len_) internal pure returns (MemView) {
        uint256 viewLen = memView.len();
        // Ensure it doesn't overrun the view
        if (len_ > viewLen) {
            revert ViewOverrun();
        }
        // Could do the unchecked math due to the check above
        uint256 index_;
        unchecked {
            index_ = viewLen - len_;
        }
        // Build a view starting from index with the given length
        unchecked {
            // len_ <= memView.len() => memView.loc() <= loc_ <= memView.end()
            return build({loc_: memView.loc() + viewLen - len_, len_: len_});
        }
    }

    // ═══════════════════════════════════════════ INDEXING MEMORY VIEW ════════════════════════════════════════════════

    /**
     * @notice Load up to 32 bytes from the view onto the stack.
     * @dev Returns a bytes32 with only the `bytes_` HIGHEST bytes set.
     * This can be immediately cast to a smaller fixed-length byte array.
     * To automatically cast to an integer, use `indexUint`.
     * @param memView       The memory view
     * @param index_        The index
     * @param bytes_        The amount of bytes to load onto the stack
     * @return result       The 32 byte result having only `bytes_` highest bytes set
     */
    function index(MemView memView, uint256 index_, uint256 bytes_) internal pure returns (bytes32 result) {
        if (bytes_ == 0) {
            return bytes32(0);
        }
        // Can't load more than 32 bytes to the stack in one go
        if (bytes_ > 32) {
            revert IndexedTooMuch();
        }
        // The last indexed byte should be within view boundaries
        if (index_ + bytes_ > memView.len()) {
            revert ViewOverrun();
        }
        uint256 bitLength = bytes_ << 3; // bytes_ * 8
        uint256 loc_ = memView.loc();
        // Get a mask with `bitLength` highest bits set
        uint256 mask;
        // 0x800...00 binary representation is 100...00
        // sar stands for "signed arithmetic shift": https://en.wikipedia.org/wiki/Arithmetic_shift
        // sar(N-1, 100...00) = 11...100..00, with exactly N highest bits set to 1
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            mask := sar(sub(bitLength, 1), 0x8000000000000000000000000000000000000000000000000000000000000000)
        }
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            // Load a full word using index offset, and apply mask to ignore non-relevant bytes
            result := and(mload(add(loc_, index_)), mask)
        }
    }

    /**
     * @notice Parse an unsigned integer from the view at `index`.
     * @dev Requires that the view have >= `bytes_` bytes following that index.
     * @param memView       The memory view
     * @param index_        The index
     * @param bytes_        The amount of bytes to load onto the stack
     * @return The unsigned integer
     */
    function indexUint(MemView memView, uint256 index_, uint256 bytes_) internal pure returns (uint256) {
        bytes32 indexedBytes = memView.index(index_, bytes_);
        // `index()` returns left-aligned `bytes_`, while integers are right-aligned
        // Shifting here to right-align with the full 32 bytes word: need to shift right `(32 - bytes_)` bytes
        unchecked {
            // memView.index() reverts when bytes_ > 32, thus unchecked math
            return uint256(indexedBytes) >> ((32 - bytes_) << 3);
        }
    }

    /**
     * @notice Parse an address from the view at `index`.
     * @dev Requires that the view have >= 20 bytes following that index.
     * @param memView       The memory view
     * @param index_        The index
     * @return The address
     */
    function indexAddress(MemView memView, uint256 index_) internal pure returns (address) {
        // index 20 bytes as `uint160`, and then cast to `address`
        return address(uint160(memView.indexUint(index_, 20)));
    }

    // ══════════════════════════════════════════════ PRIVATE HELPERS ══════════════════════════════════════════════════

    /// @dev Returns a memory view over the specified memory location
    /// without checking if it points to unallocated memory.
    function _unsafeBuildUnchecked(uint256 loc_, uint256 len_) private pure returns (MemView) {
        // There is no scenario where loc or len would overflow uint128, so we omit this check.
        // We use the highest 128 bits to encode the location and the lowest 128 bits to encode the length.
        return MemView.wrap((loc_ << 128) | len_);
    }

    /**
     * @notice Copy the view to a location, return an unsafe memory reference
     * @dev Super Dangerous direct memory access.
     * This reference can be overwritten if anything else modifies memory (!!!).
     * As such it MUST be consumed IMMEDIATELY. Update the free memory pointer to ensure the copied data
     * is not overwritten. This function is private to prevent unsafe usage by callers.
     * @param memView       The memory view
     * @param newLoc        The new location to copy the underlying view data
     * @return The memory view over the unsafe memory with the copied underlying data
     */
    function _unsafeCopyTo(MemView memView, uint256 newLoc) private view returns (MemView) {
        uint256 len_ = memView.len();
        uint256 oldLoc = memView.loc();

        uint256 ptr;
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            // Load unused memory pointer
            ptr := mload(0x40)
        }
        // Revert if we're writing in occupied memory
        if (newLoc < ptr) {
            revert OccupiedMemory();
        }
        bool res;
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            // use the identity precompile (0x04) to copy
            res := staticcall(gas(), 0x04, oldLoc, len_, newLoc, len_)
        }
        if (!res) revert PrecompileOutOfGas();
        return _unsafeBuildUnchecked({loc_: newLoc, len_: len_});
    }

    /**
     * @notice Join the views in memory, return an unsafe reference to the memory.
     * @dev Super Dangerous direct memory access.
     * This reference can be overwritten if anything else modifies memory (!!!).
     * As such it MUST be consumed IMMEDIATELY. Update the free memory pointer to ensure the copied data
     * is not overwritten. This function is private to prevent unsafe usage by callers.
     * @param memViews      The memory views
     * @return The conjoined view pointing to the new memory
     */
    function _unsafeJoin(MemView[] memory memViews, uint256 location) private view returns (MemView) {
        uint256 ptr;
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            // Load unused memory pointer
            ptr := mload(0x40)
        }
        // Revert if we're writing in occupied memory
        if (location < ptr) {
            revert OccupiedMemory();
        }
        // Copy the views to the specified location one by one, by tracking the amount of copied bytes so far
        uint256 offset = 0;
        for (uint256 i = 0; i < memViews.length;) {
            MemView memView = memViews[i];
            // We can use the unchecked math here as location + sum(view.length) will never overflow uint256
            unchecked {
                _unsafeCopyTo(memView, location + offset);
                offset += memView.len();
                ++i;
            }
        }
        return _unsafeBuildUnchecked({loc_: location, len_: offset});
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
pragma solidity 0.8.17;

import {MemView, MemViewLib} from "./MemView.sol";
import {RECEIPT_LENGTH, RECEIPT_VALID_SALT, RECEIPT_INVALID_SALT} from "../Constants.sol";
import {UnformattedReceipt} from "../Errors.sol";

/// Receipt is a memory view over a formatted "full receipt" payload.
type Receipt is uint256;

using ReceiptLib for Receipt global;

/// Receipt structure represents a Notary statement that a certain message has been executed in `ExecutionHub`.
/// - It is possible to prove the correctness of the tips payload using the message hash, therefore tips are not
///   included in the receipt.
/// - Receipt is signed by a Notary and submitted to `Summit` in order to initiate the tips distribution for an
///   executed message.
/// - If a message execution fails the first time, the `finalExecutor` field will be set to zero address. In this
///   case, when the message is finally executed successfully, the `finalExecutor` field will be updated. Both
///   receipts will be considered valid.
/// # Memory layout of Receipt fields
///
/// | Position   | Field         | Type    | Bytes | Description                                      |
/// | ---------- | ------------- | ------- | ----- | ------------------------------------------------ |
/// | [000..004) | origin        | uint32  | 4     | Domain where message originated                  |
/// | [004..008) | destination   | uint32  | 4     | Domain where message was executed                |
/// | [008..040) | messageHash   | bytes32 | 32    | Hash of the message                              |
/// | [040..072) | snapshotRoot  | bytes32 | 32    | Snapshot root used for proving the message       |
/// | [072..073) | stateIndex    | uint8   | 1     | Index of state used for the snapshot proof       |
/// | [073..093) | attNotary     | address | 20    | Notary who posted attestation with snapshot root |
/// | [093..113) | firstExecutor | address | 20    | Executor who performed first valid execution     |
/// | [113..133) | finalExecutor | address | 20    | Executor who successfully executed the message   |
library ReceiptLib {
    using MemViewLib for bytes;

    /// @dev The variables below are not supposed to be used outside of the library directly.
    uint256 private constant OFFSET_ORIGIN = 0;
    uint256 private constant OFFSET_DESTINATION = 4;
    uint256 private constant OFFSET_MESSAGE_HASH = 8;
    uint256 private constant OFFSET_SNAPSHOT_ROOT = 40;
    uint256 private constant OFFSET_STATE_INDEX = 72;
    uint256 private constant OFFSET_ATT_NOTARY = 73;
    uint256 private constant OFFSET_FIRST_EXECUTOR = 93;
    uint256 private constant OFFSET_FINAL_EXECUTOR = 113;

    // ═════════════════════════════════════════════════ RECEIPT ═════════════════════════════════════════════════════

    /**
     * @notice Returns a formatted Receipt payload with provided fields.
     * @param origin_           Domain where message originated
     * @param destination_      Domain where message was executed
     * @param messageHash_      Hash of the message
     * @param snapshotRoot_     Snapshot root used for proving the message
     * @param stateIndex_       Index of state used for the snapshot proof
     * @param attNotary_        Notary who posted attestation with snapshot root
     * @param firstExecutor_    Executor who performed first valid execution attempt
     * @param finalExecutor_    Executor who successfully executed the message
     * @return Formatted receipt
     */
    function formatReceipt(
        uint32 origin_,
        uint32 destination_,
        bytes32 messageHash_,
        bytes32 snapshotRoot_,
        uint8 stateIndex_,
        address attNotary_,
        address firstExecutor_,
        address finalExecutor_
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(
            origin_, destination_, messageHash_, snapshotRoot_, stateIndex_, attNotary_, firstExecutor_, finalExecutor_
        );
    }

    /**
     * @notice Returns a Receipt view over the given payload.
     * @dev Will revert if the payload is not a receipt.
     */
    function castToReceipt(bytes memory payload) internal pure returns (Receipt) {
        return castToReceipt(payload.ref());
    }

    /**
     * @notice Casts a memory view to a Receipt view.
     * @dev Will revert if the memory view is not over a receipt.
     */
    function castToReceipt(MemView memView) internal pure returns (Receipt) {
        if (!isReceipt(memView)) revert UnformattedReceipt();
        return Receipt.wrap(MemView.unwrap(memView));
    }

    /// @notice Checks that a payload is a formatted Receipt.
    function isReceipt(MemView memView) internal pure returns (bool) {
        // Check payload length
        return memView.len() == RECEIPT_LENGTH;
    }

    /// @notice Returns the hash of an Receipt, that could be later signed by a Notary to signal
    /// that the receipt is valid.
    function hashValid(Receipt receipt) internal pure returns (bytes32) {
        // The final hash to sign is keccak(receiptSalt, keccak(receipt))
        return receipt.unwrap().keccakSalted(RECEIPT_VALID_SALT);
    }

    /// @notice Returns the hash of a Receipt, that could be later signed by a Guard to signal
    /// that the receipt is invalid.
    function hashInvalid(Receipt receipt) internal pure returns (bytes32) {
        // The final hash to sign is keccak(receiptBodyInvalidSalt, keccak(receipt))
        return receipt.unwrap().keccakSalted(RECEIPT_INVALID_SALT);
    }

    /// @notice Convenience shortcut for unwrapping a view.
    function unwrap(Receipt receipt) internal pure returns (MemView) {
        return MemView.wrap(Receipt.unwrap(receipt));
    }

    /// @notice Compares two Receipt structures.
    function equals(Receipt a, Receipt b) internal pure returns (bool) {
        // Length of a Receipt payload is fixed, so we just need to compare the hashes
        return a.unwrap().keccak() == b.unwrap().keccak();
    }

    // ═════════════════════════════════════════════ RECEIPT SLICING ═════════════════════════════════════════════════

    /// @notice Returns receipt's origin field
    function origin(Receipt receipt) internal pure returns (uint32) {
        return uint32(receipt.unwrap().indexUint({index_: OFFSET_ORIGIN, bytes_: 4}));
    }

    /// @notice Returns receipt's destination field
    function destination(Receipt receipt) internal pure returns (uint32) {
        return uint32(receipt.unwrap().indexUint({index_: OFFSET_DESTINATION, bytes_: 4}));
    }

    /// @notice Returns receipt's "message hash" field
    function messageHash(Receipt receipt) internal pure returns (bytes32) {
        return receipt.unwrap().index({index_: OFFSET_MESSAGE_HASH, bytes_: 32});
    }

    /// @notice Returns receipt's "snapshot root" field
    function snapshotRoot(Receipt receipt) internal pure returns (bytes32) {
        return receipt.unwrap().index({index_: OFFSET_SNAPSHOT_ROOT, bytes_: 32});
    }

    /// @notice Returns receipt's "state index" field
    function stateIndex(Receipt receipt) internal pure returns (uint8) {
        return uint8(receipt.unwrap().indexUint({index_: OFFSET_STATE_INDEX, bytes_: 1}));
    }

    /// @notice Returns receipt's "attestation notary" field
    function attNotary(Receipt receipt) internal pure returns (address) {
        return receipt.unwrap().indexAddress({index_: OFFSET_ATT_NOTARY});
    }

    /// @notice Returns receipt's "first executor" field
    function firstExecutor(Receipt receipt) internal pure returns (address) {
        return receipt.unwrap().indexAddress({index_: OFFSET_FIRST_EXECUTOR});
    }

    /// @notice Returns receipt's "final executor" field
    function finalExecutor(Receipt receipt) internal pure returns (address) {
        return receipt.unwrap().indexAddress({index_: OFFSET_FINAL_EXECUTOR});
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {State, StateLib} from "./State.sol";
import {MemView, MemViewLib} from "./MemView.sol";
import {SNAPSHOT_MAX_STATES, SNAPSHOT_VALID_SALT, SNAPSHOT_TREE_HEIGHT, STATE_LENGTH} from "../Constants.sol";
import {IncorrectStatesAmount, IndexOutOfRange, UnformattedSnapshot} from "../Errors.sol";
import {MerkleMath} from "../merkle/MerkleMath.sol";
import {GasDataLib, ChainGas} from "../stack/GasData.sol";

/// Snapshot is a memory view over a formatted snapshot payload: a list of states.
type Snapshot is uint256;

using SnapshotLib for Snapshot global;

/// # Snapshot
/// Snapshot structure represents the state of multiple Origin contracts deployed on multiple chains.
/// In short, snapshot is a list of "State" structs. See State.sol for details about the "State" structs.
///
/// ## Snapshot usage
/// - Both Guards and Notaries are supposed to form snapshots and sign `snapshot.hash()` to verify its validity.
/// - Each Guard should be monitoring a set of Origin contracts chosen as they see fit.
///   - They are expected to form snapshots with Origin states for this set of chains,
///   sign and submit them to Summit contract.
/// - Notaries are expected to monitor the Summit contract for new snapshots submitted by the Guards.
///   - They should be forming their own snapshots using states from snapshots of any of the Guards.
///   - The states for the Notary snapshots don't have to come from the same Guard snapshot,
///   or don't even have to be submitted by the same Guard.
/// - With their signature, Notary effectively "notarizes" the work that some Guards have done in Summit contract.
///   - Notary signature on a snapshot doesn't only verify the validity of the Origins, but also serves as
///   a proof of liveliness for Guards monitoring these Origins.
///
/// ## Snapshot validity
/// - Snapshot is considered "valid" in Origin, if every state referring to that Origin is valid there.
/// - Snapshot is considered "globally valid", if it is "valid" in every Origin contract.
///
/// # Snapshot memory layout
///
/// | Position   | Field       | Type  | Bytes | Description                  |
/// | ---------- | ----------- | ----- | ----- | ---------------------------- |
/// | [000..050) | states[0]   | bytes | 50    | Origin State with index==0   |
/// | [050..100) | states[1]   | bytes | 50    | Origin State with index==1   |
/// | ...        | ...         | ...   | 50    | ...                          |
/// | [AAA..BBB) | states[N-1] | bytes | 50    | Origin State with index==N-1 |
///
/// @dev Snapshot could be signed by both Guards and Notaries and submitted to `Summit` in order to produce Attestations
/// that could be used in ExecutionHub for proving the messages coming from origin chains that the snapshot refers to.
library SnapshotLib {
    using MemViewLib for bytes;
    using StateLib for MemView;

    // ═════════════════════════════════════════════════ SNAPSHOT ══════════════════════════════════════════════════════

    /**
     * @notice Returns a formatted Snapshot payload using a list of States.
     * @param states    Arrays of State-typed memory views over Origin states
     * @return Formatted snapshot
     */
    function formatSnapshot(State[] memory states) internal view returns (bytes memory) {
        if (!_isValidAmount(states.length)) revert IncorrectStatesAmount();
        // First we unwrap State-typed views into untyped memory views
        uint256 length = states.length;
        MemView[] memory views = new MemView[](length);
        for (uint256 i = 0; i < length; ++i) {
            views[i] = states[i].unwrap();
        }
        // Finally, we join them in a single payload. This avoids doing unnecessary copies in the process.
        return MemViewLib.join(views);
    }

    /**
     * @notice Returns a Snapshot view over for the given payload.
     * @dev Will revert if the payload is not a snapshot payload.
     */
    function castToSnapshot(bytes memory payload) internal pure returns (Snapshot) {
        return castToSnapshot(payload.ref());
    }

    /**
     * @notice Casts a memory view to a Snapshot view.
     * @dev Will revert if the memory view is not over a snapshot payload.
     */
    function castToSnapshot(MemView memView) internal pure returns (Snapshot) {
        if (!isSnapshot(memView)) revert UnformattedSnapshot();
        return Snapshot.wrap(MemView.unwrap(memView));
    }

    /**
     * @notice Checks that a payload is a formatted Snapshot.
     */
    function isSnapshot(MemView memView) internal pure returns (bool) {
        // Snapshot needs to have exactly N * STATE_LENGTH bytes length
        // N needs to be in [1 .. SNAPSHOT_MAX_STATES] range
        uint256 length = memView.len();
        uint256 statesAmount_ = length / STATE_LENGTH;
        return statesAmount_ * STATE_LENGTH == length && _isValidAmount(statesAmount_);
    }

    /// @notice Returns the hash of a Snapshot, that could be later signed by an Agent  to signal
    /// that the snapshot is valid.
    function hashValid(Snapshot snapshot) internal pure returns (bytes32 hashedSnapshot) {
        // The final hash to sign is keccak(snapshotSalt, keccak(snapshot))
        return snapshot.unwrap().keccakSalted(SNAPSHOT_VALID_SALT);
    }

    /// @notice Convenience shortcut for unwrapping a view.
    function unwrap(Snapshot snapshot) internal pure returns (MemView) {
        return MemView.wrap(Snapshot.unwrap(snapshot));
    }

    // ═════════════════════════════════════════════ SNAPSHOT SLICING ══════════════════════════════════════════════════

    /// @notice Returns a state with a given index from the snapshot.
    function state(Snapshot snapshot, uint256 stateIndex) internal pure returns (State) {
        MemView memView = snapshot.unwrap();
        uint256 indexFrom = stateIndex * STATE_LENGTH;
        if (indexFrom >= memView.len()) revert IndexOutOfRange();
        return memView.slice({index_: indexFrom, len_: STATE_LENGTH}).castToState();
    }

    /// @notice Returns the amount of states in the snapshot.
    function statesAmount(Snapshot snapshot) internal pure returns (uint256) {
        // Each state occupies exactly `STATE_LENGTH` bytes
        return snapshot.unwrap().len() / STATE_LENGTH;
    }

    /// @notice Extracts the list of ChainGas structs from the snapshot.
    function snapGas(Snapshot snapshot) internal pure returns (ChainGas[] memory snapGas_) {
        uint256 statesAmount_ = snapshot.statesAmount();
        snapGas_ = new ChainGas[](statesAmount_);
        for (uint256 i = 0; i < statesAmount_; ++i) {
            State state_ = snapshot.state(i);
            snapGas_[i] = GasDataLib.encodeChainGas(state_.gasData(), state_.origin());
        }
    }

    // ═════════════════════════════════════════ SNAPSHOT ROOT CALCULATION ═════════════════════════════════════════════

    /// @notice Returns the root for the "Snapshot Merkle Tree" composed of state leafs from the snapshot.
    function calculateRoot(Snapshot snapshot) internal pure returns (bytes32) {
        uint256 statesAmount_ = snapshot.statesAmount();
        bytes32[] memory hashes = new bytes32[](statesAmount_);
        for (uint256 i = 0; i < statesAmount_; ++i) {
            // Each State has two sub-leafs, which are used as the "leafs" in "Snapshot Merkle Tree"
            // We save their parent in order to calculate the root for the whole tree later
            hashes[i] = snapshot.state(i).leaf();
        }
        // We are subtracting one here, as we already calculated the hashes
        // for the tree level above the "leaf level".
        MerkleMath.calculateRoot(hashes, SNAPSHOT_TREE_HEIGHT - 1);
        // hashes[0] now stores the value for the Merkle Root of the list
        return hashes[0];
    }

    /// @notice Reconstructs Snapshot merkle Root from State Merkle Data (root + origin domain)
    /// and proof of inclusion of State Merkle Data (aka State "left sub-leaf") in Snapshot Merkle Tree.
    /// > Reverts if any of these is true:
    /// > - State index is out of range.
    /// > - Snapshot Proof length exceeds Snapshot tree Height.
    /// @param originRoot    Root of Origin Merkle Tree
    /// @param domain        Domain of Origin chain
    /// @param snapProof     Proof of inclusion of State Merkle Data into Snapshot Merkle Tree
    /// @param stateIndex    Index of Origin State in the Snapshot
    function proofSnapRoot(bytes32 originRoot, uint32 domain, bytes32[] memory snapProof, uint256 stateIndex)
        internal
        pure
        returns (bytes32)
    {
        // Index of "leftLeaf" is twice the state position in the snapshot
        uint256 leftLeafIndex = stateIndex << 1;
        // Check that "leftLeaf" index fits into Snapshot Merkle Tree
        if (leftLeafIndex >= (1 << SNAPSHOT_TREE_HEIGHT)) revert IndexOutOfRange();
        // Reconstruct left sub-leaf of the Origin State: (originRoot, originDomain)
        bytes32 leftLeaf = StateLib.leftLeaf(originRoot, domain);
        // Reconstruct snapshot root using proof of inclusion
        // This will revert if snapshot proof length exceeds Snapshot Tree Height
        return MerkleMath.proofRoot(leftLeafIndex, leftLeaf, snapProof, SNAPSHOT_TREE_HEIGHT);
    }

    // ══════════════════════════════════════════════ PRIVATE HELPERS ══════════════════════════════════════════════════

    /// @dev Checks if snapshot's states amount is valid.
    function _isValidAmount(uint256 statesAmount_) internal pure returns (bool) {
        // Need to have at least one state in a snapshot.
        // Also need to have no more than `SNAPSHOT_MAX_STATES` states in a snapshot.
        return statesAmount_ != 0 && statesAmount_ <= SNAPSHOT_MAX_STATES;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {MemView, MemViewLib} from "./MemView.sol";
import {GAS_DATA_LENGTH, STATE_LENGTH, STATE_INVALID_SALT} from "../Constants.sol";
import {UnformattedState} from "../Errors.sol";
import {GasData, GasDataLib} from "../stack/GasData.sol";

/// State is a memory view over a formatted state payload.
type State is uint256;

using StateLib for State global;

/// # State
/// State structure represents the state of Origin contract at some point of time.
/// - State is structured in a way to track the updates of the Origin Merkle Tree.
/// - State includes root of the Origin Merkle Tree, origin domain and some additional metadata.
/// ## Origin Merkle Tree
/// Hash of every sent message is inserted in the Origin Merkle Tree, which changes
/// the value of Origin Merkle Root (which is the root for the mentioned tree).
/// - Origin has a single Merkle Tree for all messages, regardless of their destination domain.
/// - This leads to Origin state being updated if and only if a message was sent in a block.
/// - Origin contract is a "source of truth" for states: a state is considered "valid" in its Origin,
/// if it matches the state of the Origin contract after the N-th (nonce) message was sent.
///
/// # Memory layout of State fields
///
/// | Position   | Field       | Type    | Bytes | Description                    |
/// | ---------- | ----------- | ------- | ----- | ------------------------------ |
/// | [000..032) | root        | bytes32 | 32    | Root of the Origin Merkle Tree |
/// | [032..036) | origin      | uint32  | 4     | Domain where Origin is located |
/// | [036..040) | nonce       | uint32  | 4     | Amount of sent messages        |
/// | [040..045) | blockNumber | uint40  | 5     | Block of last sent message     |
/// | [045..050) | timestamp   | uint40  | 5     | Time of last sent message      |
/// | [050..062) | gasData     | uint96  | 12    | Gas data for the chain         |
///
/// @dev State could be used to form a Snapshot to be signed by a Guard or a Notary.
library StateLib {
    using MemViewLib for bytes;

    /// @dev The variables below are not supposed to be used outside of the library directly.
    uint256 private constant OFFSET_ROOT = 0;
    uint256 private constant OFFSET_ORIGIN = 32;
    uint256 private constant OFFSET_NONCE = 36;
    uint256 private constant OFFSET_BLOCK_NUMBER = 40;
    uint256 private constant OFFSET_TIMESTAMP = 45;
    uint256 private constant OFFSET_GAS_DATA = 50;

    // ═══════════════════════════════════════════════════ STATE ═══════════════════════════════════════════════════════

    /**
     * @notice Returns a formatted State payload with provided fields
     * @param root_         New merkle root
     * @param origin_       Domain of Origin's chain
     * @param nonce_        Nonce of the merkle root
     * @param blockNumber_  Block number when root was saved in Origin
     * @param timestamp_    Block timestamp when root was saved in Origin
     * @param gasData_      Gas data for the chain
     * @return Formatted state
     */
    function formatState(
        bytes32 root_,
        uint32 origin_,
        uint32 nonce_,
        uint40 blockNumber_,
        uint40 timestamp_,
        GasData gasData_
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(root_, origin_, nonce_, blockNumber_, timestamp_, gasData_);
    }

    /**
     * @notice Returns a State view over the given payload.
     * @dev Will revert if the payload is not a state.
     */
    function castToState(bytes memory payload) internal pure returns (State) {
        return castToState(payload.ref());
    }

    /**
     * @notice Casts a memory view to a State view.
     * @dev Will revert if the memory view is not over a state.
     */
    function castToState(MemView memView) internal pure returns (State) {
        if (!isState(memView)) revert UnformattedState();
        return State.wrap(MemView.unwrap(memView));
    }

    /// @notice Checks that a payload is a formatted State.
    function isState(MemView memView) internal pure returns (bool) {
        return memView.len() == STATE_LENGTH;
    }

    /// @notice Returns the hash of a State, that could be later signed by a Guard to signal
    /// that the state is invalid.
    function hashInvalid(State state) internal pure returns (bytes32) {
        // The final hash to sign is keccak(stateInvalidSalt, keccak(state))
        return state.unwrap().keccakSalted(STATE_INVALID_SALT);
    }

    /// @notice Convenience shortcut for unwrapping a view.
    function unwrap(State state) internal pure returns (MemView) {
        return MemView.wrap(State.unwrap(state));
    }

    /// @notice Compares two State structures.
    function equals(State a, State b) internal pure returns (bool) {
        // Length of a State payload is fixed, so we just need to compare the hashes
        return a.unwrap().keccak() == b.unwrap().keccak();
    }

    // ═══════════════════════════════════════════════ STATE HASHING ═══════════════════════════════════════════════════

    /// @notice Returns the hash of the State.
    /// @dev We are using the Merkle Root of a tree with two leafs (see below) as state hash.
    function leaf(State state) internal pure returns (bytes32) {
        (bytes32 leftLeaf_, bytes32 rightLeaf_) = state.subLeafs();
        // Final hash is the parent of these leafs
        return keccak256(bytes.concat(leftLeaf_, rightLeaf_));
    }

    /// @notice Returns "sub-leafs" of the State. Hash of these "sub leafs" is going to be used
    /// as a "state leaf" in the "Snapshot Merkle Tree".
    /// This enables proving that leftLeaf = (root, origin) was a part of the "Snapshot Merkle Tree",
    /// by combining `rightLeaf` with the remainder of the "Snapshot Merkle Proof".
    function subLeafs(State state) internal pure returns (bytes32 leftLeaf_, bytes32 rightLeaf_) {
        MemView memView = state.unwrap();
        // Left leaf is (root, origin)
        leftLeaf_ = memView.prefix({len_: OFFSET_NONCE}).keccak();
        // Right leaf is (metadata), or (nonce, blockNumber, timestamp)
        rightLeaf_ = memView.sliceFrom({index_: OFFSET_NONCE}).keccak();
    }

    /// @notice Returns the left "sub-leaf" of the State.
    function leftLeaf(bytes32 root_, uint32 origin_) internal pure returns (bytes32) {
        // We use encodePacked here to simulate the State memory layout
        return keccak256(abi.encodePacked(root_, origin_));
    }

    /// @notice Returns the right "sub-leaf" of the State.
    function rightLeaf(uint32 nonce_, uint40 blockNumber_, uint40 timestamp_, GasData gasData_)
        internal
        pure
        returns (bytes32)
    {
        // We use encodePacked here to simulate the State memory layout
        return keccak256(abi.encodePacked(nonce_, blockNumber_, timestamp_, gasData_));
    }

    // ═══════════════════════════════════════════════ STATE SLICING ═══════════════════════════════════════════════════

    /// @notice Returns a historical Merkle root from the Origin contract.
    function root(State state) internal pure returns (bytes32) {
        return state.unwrap().index({index_: OFFSET_ROOT, bytes_: 32});
    }

    /// @notice Returns domain of chain where the Origin contract is deployed.
    function origin(State state) internal pure returns (uint32) {
        return uint32(state.unwrap().indexUint({index_: OFFSET_ORIGIN, bytes_: 4}));
    }

    /// @notice Returns nonce of Origin contract at the time, when `root` was the Merkle root.
    function nonce(State state) internal pure returns (uint32) {
        return uint32(state.unwrap().indexUint({index_: OFFSET_NONCE, bytes_: 4}));
    }

    /// @notice Returns a block number when `root` was saved in Origin.
    function blockNumber(State state) internal pure returns (uint40) {
        return uint40(state.unwrap().indexUint({index_: OFFSET_BLOCK_NUMBER, bytes_: 5}));
    }

    /// @notice Returns a block timestamp when `root` was saved in Origin.
    /// @dev This is the timestamp according to the origin chain.
    function timestamp(State state) internal pure returns (uint40) {
        return uint40(state.unwrap().indexUint({index_: OFFSET_TIMESTAMP, bytes_: 5}));
    }

    /// @notice Returns gas data for the chain.
    function gasData(State state) internal pure returns (GasData) {
        return GasDataLib.wrapGasData(state.unwrap().indexUint({index_: OFFSET_GAS_DATA, bytes_: GAS_DATA_LENGTH}));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

abstract contract StatementInboxEvents {
    // ════════════════════════════════════════════ STATEMENT ACCEPTED ═════════════════════════════════════════════════

    /**
     * @notice Emitted when a snapshot is accepted by the Destination contract.
     * @param domain        Domain where the signed Notary is active
     * @param notary        Notary who signed the attestation
     * @param attPayload    Raw payload with attestation data
     * @param attSignature  Notary signature for the attestation
     */
    event AttestationAccepted(uint32 domain, address notary, bytes attPayload, bytes attSignature);

    // ═════════════════════════════════════════ INVALID STATEMENT PROVED ══════════════════════════════════════════════

    /**
     * @notice Emitted when a proof of invalid receipt statement is submitted.
     * @param rcptPayload   Raw payload with the receipt statement
     * @param rcptSignature Notary signature for the receipt statement
     */
    event InvalidReceipt(bytes rcptPayload, bytes rcptSignature);

    /**
     * @notice Emitted when a proof of invalid receipt report is submitted.
     * @param rrPayload     Raw payload with report data
     * @param rrSignature   Guard signature for the report
     */
    event InvalidReceiptReport(bytes rrPayload, bytes rrSignature);

    /**
     * @notice Emitted when a proof of invalid state in the signed attestation is submitted.
     * @param stateIndex    Index of invalid state in the snapshot
     * @param statePayload  Raw payload with state data
     * @param attPayload    Raw payload with Attestation data for snapshot
     * @param attSignature  Notary signature for the attestation
     */
    event InvalidStateWithAttestation(uint256 stateIndex, bytes statePayload, bytes attPayload, bytes attSignature);

    /**
     * @notice Emitted when a proof of invalid state in the signed snapshot is submitted.
     * @param stateIndex    Index of invalid state in the snapshot
     * @param snapPayload   Raw payload with snapshot data
     * @param snapSignature Agent signature for the snapshot
     */
    event InvalidStateWithSnapshot(uint256 stateIndex, bytes snapPayload, bytes snapSignature);

    /**
     * @notice Emitted when a proof of invalid state report is submitted.
     * @param srPayload     Raw payload with report data
     * @param srSignature   Guard signature for the report
     */
    event InvalidStateReport(bytes srPayload, bytes srSignature);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {MessageStatus} from "../libs/Structures.sol";

interface IExecutionHub {
    /**
     * @notice Attempts to prove inclusion of message into one of Snapshot Merkle Trees,
     * previously submitted to this contract in a form of a signed Attestation.
     * Proven message is immediately executed by passing its contents to the specified recipient.
     * @dev Will revert if any of these is true:
     *  - Message payload is not properly formatted.
     *  - Snapshot root (reconstructed from message hash and proofs) is unknown
     *  - Snapshot root is known, but was submitted by an inactive Notary
     *  - Snapshot root is known, but optimistic period for a message hasn't passed
     *  - Provided gas limit is lower than the one requested in the message
     *  - Recipient doesn't implement a `handle` method (refer to IMessageRecipient.sol)
     *  - Recipient reverted upon receiving a message
     * Note: refer to libs/memory/State.sol for details about Origin State's sub-leafs.
     * @param msgPayload    Raw payload with a formatted message to execute
     * @param originProof   Proof of inclusion of message in the Origin Merkle Tree
     * @param snapProof     Proof of inclusion of Origin State's Left Leaf into Snapshot Merkle Tree
     * @param stateIndex    Index of Origin State in the Snapshot
     * @param gasLimit      Gas limit for message execution
     */
    function execute(
        bytes memory msgPayload,
        bytes32[] calldata originProof,
        bytes32[] calldata snapProof,
        uint256 stateIndex,
        uint64 gasLimit
    ) external;

    // ═══════════════════════════════════════════════════ VIEWS ═══════════════════════════════════════════════════════

    /**
     * @notice Returns attestation nonce for a given snapshot root.
     * @dev Will return 0 if the root is unknown.
     */
    function getAttestationNonce(bytes32 snapRoot) external view returns (uint32 attNonce);

    /**
     * @notice Checks the validity of the unsigned message receipt.
     * @dev Will revert if any of these is true:
     *  - Receipt payload is not properly formatted.
     *  - Receipt signer is not an active Notary.
     *  - Receipt destination chain does not refer to this chain.
     * @param rcptPayload       Raw payload with Receipt data
     * @return isValid          Whether the requested receipt is valid.
     */
    function isValidReceipt(bytes memory rcptPayload) external view returns (bool isValid);

    /**
     * @notice Returns message execution status: None/Failed/Success.
     * @param messageHash       Hash of the message payload
     * @return status           Message execution status
     */
    function messageStatus(bytes32 messageHash) external view returns (MessageStatus status);

    /**
     * @notice Returns a formatted payload with the message receipt.
     * @dev Notaries could derive the tips, and the tips proof using the message payload, and submit
     * the signed receipt with the proof of tips to `Summit` in order to initiate tips distribution.
     * @param messageHash       Hash of the message payload
     * @return data             Formatted payload with the message execution receipt
     */
    function messageReceipt(bytes32 messageHash) external view returns (bytes memory data);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IStateHub {
    /**
     * @notice Check that a given state is valid: matches the historical state of Origin contract.
     * Note: any Agent including an invalid state in their snapshot will be slashed
     * upon providing the snapshot and agent signature for it to Origin contract.
     * @dev Will revert if any of these is true:
     *  - State payload is not properly formatted.
     * @param statePayload      Raw payload with state data
     * @return isValid          Whether the provided state is valid
     */
    function isValidState(bytes memory statePayload) external view returns (bool isValid);

    /**
     * @notice Returns the amount of saved states so far.
     * @dev This includes the initial state of "empty Origin Merkle Tree".
     */
    function statesAmount() external view returns (uint256);

    /**
     * @notice Suggest the data (state after latest sent message) to sign for an Agent.
     * Note: signing the suggested state data will will never lead to slashing of the actor,
     * assuming they have confirmed that the block, which number is included in the data,
     * is not subject to reorganization (which is different for every observed chain).
     * @return statePayload     Raw payload with the latest state data
     */
    function suggestLatestState() external view returns (bytes memory statePayload);

    /**
     * @notice Given the historical nonce, suggest the state data to sign for an Agent.
     * Note: signing the suggested state data will will never lead to slashing of the actor,
     * assuming they have confirmed that the block, which number is included in the data,
     * is not subject to reorganization (which is different for every observed chain).
     * @param nonce             Historical nonce to form a state
     * @return statePayload     Raw payload with historical state data
     */
    function suggestState(uint32 nonce) external view returns (bytes memory statePayload);
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
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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