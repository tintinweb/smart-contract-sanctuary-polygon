// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IncorrectDestinationDomain, LocalGasDataNotSet, RemoteGasDataNotSet} from "./libs/Errors.sol";
import {GasData, GasDataLib} from "./libs/stack/GasData.sol";
import {Number, NumberLib} from "./libs/stack/Number.sol";
import {Request, RequestLib} from "./libs/stack/Request.sol";
import {Tips, TipsLib} from "./libs/stack/Tips.sol";
// ═════════════════════════════ INTERNAL IMPORTS ══════════════════════════════
import {MessagingBase} from "./base/MessagingBase.sol";
import {GasOracleEvents} from "./events/GasOracleEvents.sol";
import {InterfaceDestination} from "./interfaces/InterfaceDestination.sol";
import {InterfaceGasOracle} from "./interfaces/InterfaceGasOracle.sol";

/**
 * @notice `GasOracle` contract is responsible for tracking the gas data for both local and remote chains.
 * ## Local gas data tracking
 * - `GasOracle` is using the available tools such as `tx.gasprice` to track the time-averaged values
 * for different "gas statistics" _(to be implemented in the future)_.
 * - These values are cached, so that the reported values are only changed when a big enough change is detected.
 * - In the MVP version the gas data is set manually by the owner of the contract.
 * - The reported values are included in Origin's State, whenever a new message is sent.
 * > This leads to cached "chain gas data" being included in the Guard and Notary snapshots.
 * ## Remote gas data tracking
 * - To track gas data for the remote chains, GasOracle relies on the Notaries to pass the gas data alongside
 * their attestations.
 * - As the gas data is cached, this leads to a storage write only when the gas data
 * for the remote chain changes significantly.
 * - GasOracle is in charge of enforcing the optimistic periods for the gas data it gets from `Destination`.
 * - The optimistic period is smaller when the "gas statistics" are increasing, and bigger when they are decreasing.
 * > Reason for that is that the decrease of the gas price leads to lower execution/delivery tips, and we want the
 * > Executors to be protected against that.
 */
contract GasOracle is MessagingBase, GasOracleEvents, InterfaceGasOracle {
    // ══════════════════════════════════════════ IMMUTABLES & CONSTANTS ═══════════════════════════════════════════════

    address public immutable destination;

    // TODO: come up with refined values for the optimistic periods
    uint256 public constant GAS_DATA_INCREASED_OPTIMISTIC_PERIOD = 5 minutes;
    uint256 public constant GAS_DATA_DECREASED_OPTIMISTIC_PERIOD = 1 hours;

    // ══════════════════════════════════════════════════ STORAGE ══════════════════════════════════════════════════════

    mapping(uint32 => GasData) internal _gasData;

    // Fixed value for the summit tip, denominated in Ethereum Mainnet Wei.
    uint256 internal _summitTipWei;

    // ═════════════════════════════════════════ CONSTRUCTOR & INITIALIZER ═════════════════════════════════════════════

    constructor(uint32 domain, address destination_) MessagingBase("0.0.3", domain) {
        destination = destination_;
    }

    /// @notice Initializes GasOracle contract:
    /// - msg.sender is set as contract owner
    function initialize() external initializer {
        // Initialize Ownable: msg.sender is set as "owner"
        __Ownable_init();
    }

    /// @notice MVP function to set the gas data for the given domain.
    function setGasData(
        uint32 domain,
        uint256 gasPrice,
        uint256 dataPrice,
        uint256 execBuffer,
        uint256 amortAttCost,
        uint256 etherPrice,
        uint256 markup
    ) external onlyOwner {
        GasData updatedGasData = GasDataLib.encodeGasData({
            gasPrice_: NumberLib.compress(gasPrice),
            dataPrice_: NumberLib.compress(dataPrice),
            execBuffer_: NumberLib.compress(execBuffer),
            amortAttCost_: NumberLib.compress(amortAttCost),
            etherPrice_: NumberLib.compress(etherPrice),
            markup_: NumberLib.compress(markup)
        });
        if (GasData.unwrap(updatedGasData) != GasData.unwrap(_gasData[domain])) {
            _setGasData(domain, updatedGasData);
        }
    }

    /// @notice MVP function to set the summit tip.
    function setSummitTip(uint256 summitTipWei) external onlyOwner {
        _summitTipWei = summitTipWei;
    }

    /// @inheritdoc InterfaceGasOracle
    function updateGasData(uint32 domain) external {
        (bool wasUpdated, GasData updatedGasData) = _fetchGasData(domain);
        if (wasUpdated) {
            _setGasData(domain, updatedGasData);
        }
    }

    /// @inheritdoc InterfaceGasOracle
    function getDecodedGasData(uint32 domain)
        external
        view
        returns (
            uint256 gasPrice,
            uint256 dataPrice,
            uint256 execBuffer,
            uint256 amortAttCost,
            uint256 etherPrice,
            uint256 markup
        )
    {
        GasData gasData = _gasData[domain];
        gasPrice = NumberLib.decompress(gasData.gasPrice());
        dataPrice = NumberLib.decompress(gasData.dataPrice());
        execBuffer = NumberLib.decompress(gasData.execBuffer());
        amortAttCost = NumberLib.decompress(gasData.amortAttCost());
        etherPrice = NumberLib.decompress(gasData.etherPrice());
        markup = NumberLib.decompress(gasData.markup());
    }

    /// @inheritdoc InterfaceGasOracle
    function getGasData() external view returns (uint256 paddedGasData) {
        return GasData.unwrap(_gasData[localDomain]);
    }

    /// @inheritdoc InterfaceGasOracle
    function getMinimumTips(uint32 destination_, uint256 paddedRequest, uint256 contentLength)
        external
        view
        returns (uint256 paddedTips)
    {
        if (destination_ == localDomain) revert IncorrectDestinationDomain();
        GasData localGasData = _gasData[localDomain];
        uint256 localEtherPrice = localGasData.etherPrice().decompress();
        if (localEtherPrice == 0) revert LocalGasDataNotSet();
        GasData remoteGasData = _gasData[destination_];
        uint256 remoteEtherPrice = remoteGasData.etherPrice().decompress();
        if (remoteEtherPrice == 0) revert RemoteGasDataNotSet();
        Request request = RequestLib.wrapPadded(paddedRequest);
        // TODO: figure out unchecked math
        // We store the fixed value of the summit tip in Ethereum Mainnet Wei already.
        // To convert it to local Ether, we need to divide by the local Ether price (using BWAD math).
        uint256 summitTip = (_summitTipWei << NumberLib.BWAD_SHIFT) / localEtherPrice;
        // To convert the cost from remote Ether to local Ether, we need to multiply by the ratio of the Ether prices.
        uint256 attestationTip = remoteGasData.amortAttCost().decompress() * remoteEtherPrice / localEtherPrice;
        // Total cost for Executor to execute a message on the remote chain has three components:
        // - Execution: gas price * requested gas limit
        // - Calldata: data price * content length
        // - Buffer: additional fee to account for computations before and after the actual execution
        // Same logic for converting the cost from remote Ether to local Ether applies here.
        // forgefmt: disable-next-item
        uint256 executionTip = (
            remoteGasData.gasPrice().decompress() * request.gasLimit() + 
            remoteGasData.dataPrice().decompress() * contentLength +
            remoteGasData.execBuffer().decompress()
        ) * remoteEtherPrice / localEtherPrice;
        // Markup for executionTip is assigned to the Delivery tip. Markup is denominated in BWAD units.
        // Execution tip is already denominated in local Ether units.
        uint256 deliveryTip = (executionTip * remoteGasData.markup().decompress()) >> NumberLib.BWAD_SHIFT;
        // The price of the gas airdrop is also included in the Delivery tip.
        // TODO: enable when gasDrop is implemented
        // deliveryTip += request.gasDrop() * remoteEtherPrice / localEtherPrice;
        // Use calculated values to encode the tips.
        return Tips.unwrap(
            TipsLib.encodeTips256({
                summitTip_: summitTip,
                attestationTip_: attestationTip,
                executionTip_: executionTip,
                deliveryTip_: deliveryTip
            })
        );
    }

    // ══════════════════════════════════════════════ INTERNAL LOGIC ═══════════════════════════════════════════════════

    /// @dev Sets the gas data for the given domain, and emits a corresponding event.
    function _setGasData(uint32 domain, GasData updatedGasData) internal {
        _gasData[domain] = updatedGasData;
        emit GasDataUpdated(domain, GasData.unwrap(updatedGasData));
    }

    // ══════════════════════════════════════════════ INTERNAL VIEWS ═══════════════════════════════════════════════════

    /// @dev Returns the updated gas data for the given domain by
    /// optimistically consuming the data from the `Destination` contract.
    function _fetchGasData(uint32 domain) internal view returns (bool wasUpdated, GasData updatedGasData) {
        GasData current = _gasData[domain];
        // Destination only has the gas data for the remote domains.
        if (domain == localDomain) return (false, current);
        (GasData incoming, uint256 dataMaturity) = InterfaceDestination(destination).getGasData(domain);
        // Zero maturity means that either there is no data for the domain, or it was just updated.
        // In both cases, we don't want to update the local data.
        if (dataMaturity == 0) return (false, current);
        // Update each gas parameter separately.
        updatedGasData = GasDataLib.encodeGasData({
            gasPrice_: _updateGasParameter(current.gasPrice(), incoming.gasPrice(), dataMaturity),
            dataPrice_: _updateGasParameter(current.dataPrice(), incoming.dataPrice(), dataMaturity),
            execBuffer_: _updateGasParameter(current.execBuffer(), incoming.execBuffer(), dataMaturity),
            amortAttCost_: _updateGasParameter(current.amortAttCost(), incoming.amortAttCost(), dataMaturity),
            etherPrice_: _updateGasParameter(current.etherPrice(), incoming.etherPrice(), dataMaturity),
            markup_: _updateGasParameter(current.markup(), incoming.markup(), dataMaturity)
        });
        wasUpdated = GasData.unwrap(updatedGasData) != GasData.unwrap(current);
    }

    /// @dev Returns the updated value for the gas parameter, given the maturity of the incoming data.
    function _updateGasParameter(Number current, Number incoming, uint256 dataMaturity)
        internal
        pure
        returns (Number updatedParameter)
    {
        // We apply the incoming value only if its optimistic period has passed.
        // The optimistic period is smaller when the the value is increasing, and bigger when it is decreasing.
        if (incoming.decompress() > current.decompress()) {
            return dataMaturity < GAS_DATA_INCREASED_OPTIMISTIC_PERIOD ? current : incoming;
        } else {
            return dataMaturity < GAS_DATA_DECREASED_OPTIMISTIC_PERIOD ? current : incoming;
        }
    }
}

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

/// Request is encoded data with "message execution request".
type Request is uint192;

using RequestLib for Request global;

/// Library for formatting _the request part_ of _the base messages_.
/// - Request represents a message sender requirements for the message execution on the destination chain.
/// - Request occupies a single storage word, and thus is stored on stack instead of being stored in memory.
/// > gasDrop field is included for future compatibility and is ignored at the moment.
///
/// # Request stack layout (from highest bits to lowest)
///
/// | Position   | Field    | Type   | Bytes | Description                                          |
/// | ---------- | -------- | ------ | ----- | ---------------------------------------------------- |
/// | (024..012] | gasDrop  | uint96 | 12    | Minimum amount of gas token to drop to the recipient |
/// | (012..004] | gasLimit | uint64 | 8     | Minimum amount of gas units to supply for execution  |
/// | (004..000] | version  | uint32 | 4     | Base message version to pass to the recipient        |

library RequestLib {
    /// @dev Amount of bits to shift to gasDrop field
    uint192 private constant SHIFT_GAS_DROP = 12 * 8;
    /// @dev Amount of bits to shift to gasLimit field
    uint192 private constant SHIFT_GAS_LIMIT = 4 * 8;

    /// @notice Returns an encoded request with the given fields
    /// @param gasDrop_     Minimum amount of gas token to drop to the recipient (ignored at the moment)
    /// @param gasLimit_    Minimum amount of gas units to supply for execution
    /// @param version_     Base message version to pass to the recipient
    function encodeRequest(uint96 gasDrop_, uint64 gasLimit_, uint32 version_) internal pure returns (Request) {
        return Request.wrap(uint192(gasDrop_) << SHIFT_GAS_DROP | uint192(gasLimit_) << SHIFT_GAS_LIMIT | version_);
    }

    /// @notice Wraps the padded encoded request into a Request-typed value.
    /// @dev The "padded" request is simply an encoded request casted to uint256 (highest bits are set to zero).
    /// Casting to uint256 is done automatically in Solidity, so no extra actions from consumers are needed.
    /// The highest bits are discarded, so that the contracts dealing with encoded requests
    /// don't need to be updated, if a new field is added.
    function wrapPadded(uint256 paddedRequest) internal pure returns (Request) {
        return Request.wrap(uint192(paddedRequest));
    }

    /// @notice Returns the requested of gas token to drop to the recipient.
    function gasDrop(Request request) internal pure returns (uint96) {
        // Casting to uint96 will truncate the highest bits, which is the behavior we want
        return uint96(Request.unwrap(request) >> SHIFT_GAS_DROP);
    }

    /// @notice Returns the requested minimum amount of gas units to supply for execution.
    function gasLimit(Request request) internal pure returns (uint64) {
        // Casting to uint64 will truncate the highest bits, which is the behavior we want
        return uint64(Request.unwrap(request) >> SHIFT_GAS_LIMIT);
    }

    /// @notice Returns the requested base message version to pass to the recipient.
    function version(Request request) internal pure returns (uint32) {
        // Casting to uint32 will truncate the highest bits, which is the behavior we want
        return uint32(Request.unwrap(request));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {TIPS_GRANULARITY} from "../Constants.sol";
import {TipsOverflow, TipsValueTooLow} from "../Errors.sol";

/// Tips is encoded data with "tips paid for sending a base message".
/// Note: even though uint256 is also an underlying type for MemView, Tips is stored ON STACK.
type Tips is uint256;

using TipsLib for Tips global;

/// # Tips
/// Library for formatting _the tips part_ of _the base messages_.
///
/// ## How the tips are awarded
/// Tips are paid for sending a base message, and are split across all the agents that
/// made the message execution on destination chain possible.
/// ### Summit tips
/// Split between:
///     - Guard posting a snapshot with state ST_G for the origin chain.
///     - Notary posting a snapshot SN_N using ST_G. This creates attestation A.
///     - Notary posting a message receipt after it is executed on destination chain.
/// ### Attestation tips
/// Paid to:
///     - Notary posting attestation A to destination chain.
/// ### Execution tips
/// Paid to:
///     - First executor performing a valid execution attempt (correct proofs, optimistic period over),
///      using attestation A to prove message inclusion on origin chain, whether the recipient reverted or not.
/// ### Delivery tips.
/// Paid to:
///     - Executor who successfully executed the message on destination chain.
///
/// ## Tips encoding
/// - Tips occupy a single storage word, and thus are stored on stack instead of being stored in memory.
/// - The actual tip values should be determined by multiplying stored values by divided by TIPS_MULTIPLIER=2**32.
/// - Tips are packed into a single word of storage, while allowing real values up to ~8*10**28 for every tip category.
/// > The only downside is that the "real tip values" are now multiplies of ~4*10**9, which should be fine even for
/// the chains with the most expensive gas currency.
/// # Tips stack layout (from highest bits to lowest)
///
/// | Position   | Field          | Type   | Bytes | Description                                                |
/// | ---------- | -------------- | ------ | ----- | ---------------------------------------------------------- |
/// | (032..024] | summitTip      | uint64 | 8     | Tip for agents interacting with Summit contract            |
/// | (024..016] | attestationTip | uint64 | 8     | Tip for Notary posting attestation to Destination contract |
/// | (016..008] | executionTip   | uint64 | 8     | Tip for valid execution attempt on destination chain       |
/// | (008..000] | deliveryTip    | uint64 | 8     | Tip for successful message delivery on destination chain   |

library TipsLib {
    /// @dev Amount of bits to shift to summitTip field
    uint256 private constant SHIFT_SUMMIT_TIP = 24 * 8;
    /// @dev Amount of bits to shift to attestationTip field
    uint256 private constant SHIFT_ATTESTATION_TIP = 16 * 8;
    /// @dev Amount of bits to shift to executionTip field
    uint256 private constant SHIFT_EXECUTION_TIP = 8 * 8;

    // ═══════════════════════════════════════════════════ TIPS ════════════════════════════════════════════════════════

    /// @notice Returns encoded tips with the given fields
    /// @param summitTip_        Tip for agents interacting with Summit contract, divided by TIPS_MULTIPLIER
    /// @param attestationTip_   Tip for Notary posting attestation to Destination contract, divided by TIPS_MULTIPLIER
    /// @param executionTip_     Tip for valid execution attempt on destination chain, divided by TIPS_MULTIPLIER
    /// @param deliveryTip_      Tip for successful message delivery on destination chain, divided by TIPS_MULTIPLIER
    function encodeTips(uint64 summitTip_, uint64 attestationTip_, uint64 executionTip_, uint64 deliveryTip_)
        internal
        pure
        returns (Tips)
    {
        return Tips.wrap(
            uint256(summitTip_) << SHIFT_SUMMIT_TIP | uint256(attestationTip_) << SHIFT_ATTESTATION_TIP
                | uint256(executionTip_) << SHIFT_EXECUTION_TIP | uint256(deliveryTip_)
        );
    }

    /// @notice Convenience function to encode tips with uint256 values.
    function encodeTips256(uint256 summitTip_, uint256 attestationTip_, uint256 executionTip_, uint256 deliveryTip_)
        internal
        pure
        returns (Tips)
    {
        return encodeTips({
            summitTip_: uint64(summitTip_ >> TIPS_GRANULARITY),
            attestationTip_: uint64(attestationTip_ >> TIPS_GRANULARITY),
            executionTip_: uint64(executionTip_ >> TIPS_GRANULARITY),
            deliveryTip_: uint64(deliveryTip_ >> TIPS_GRANULARITY)
        });
    }

    /// @notice Wraps the padded encoded tips into a Tips-typed value.
    /// @dev There is no actual padding here, as the underlying type is already uint256,
    /// but we include this function for consistency and to be future-proof, if tips will eventually use anything
    /// smaller than uint256.
    function wrapPadded(uint256 paddedTips) internal pure returns (Tips) {
        return Tips.wrap(paddedTips);
    }

    /**
     * @notice Returns a formatted Tips payload specifying empty tips.
     * @return Formatted tips
     */
    function emptyTips() internal pure returns (Tips) {
        return Tips.wrap(0);
    }

    /// @notice Returns tips's hash: a leaf to be inserted in the "Message mini-Merkle tree".
    function leaf(Tips tips) internal pure returns (bytes32 hashedTips) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Store tips in scratch space
            mstore(0, tips)
            // Compute hash of tips padded to 32 bytes
            hashedTips := keccak256(0, 32)
        }
    }

    // ═══════════════════════════════════════════════ TIPS SLICING ════════════════════════════════════════════════════

    /// @notice Returns summitTip field
    function summitTip(Tips tips) internal pure returns (uint64) {
        // Casting to uint64 will truncate the highest bits, which is the behavior we want
        return uint64(Tips.unwrap(tips) >> SHIFT_SUMMIT_TIP);
    }

    /// @notice Returns attestationTip field
    function attestationTip(Tips tips) internal pure returns (uint64) {
        // Casting to uint64 will truncate the highest bits, which is the behavior we want
        return uint64(Tips.unwrap(tips) >> SHIFT_ATTESTATION_TIP);
    }

    /// @notice Returns executionTip field
    function executionTip(Tips tips) internal pure returns (uint64) {
        // Casting to uint64 will truncate the highest bits, which is the behavior we want
        return uint64(Tips.unwrap(tips) >> SHIFT_EXECUTION_TIP);
    }

    /// @notice Returns deliveryTip field
    function deliveryTip(Tips tips) internal pure returns (uint64) {
        // Casting to uint64 will truncate the highest bits, which is the behavior we want
        return uint64(Tips.unwrap(tips));
    }

    // ════════════════════════════════════════════════ TIPS VALUE ═════════════════════════════════════════════════════

    /// @notice Returns total value of the tips payload.
    /// This is the sum of the encoded values, scaled up by TIPS_MULTIPLIER
    function value(Tips tips) internal pure returns (uint256 value_) {
        value_ = uint256(tips.summitTip()) + tips.attestationTip() + tips.executionTip() + tips.deliveryTip();
        value_ <<= TIPS_GRANULARITY;
    }

    /// @notice Increases the delivery tip to match the new value.
    function matchValue(Tips tips, uint256 newValue) internal pure returns (Tips newTips) {
        uint256 oldValue = tips.value();
        if (newValue < oldValue) revert TipsValueTooLow();
        // We want to increase the delivery tip, while keeping the other tips the same
        unchecked {
            uint256 delta = (newValue - oldValue) >> TIPS_GRANULARITY;
            // `delta` fits into uint224, as TIPS_GRANULARITY is 32, so this never overflows uint256.
            // In practice, this will never overflow uint64 as well, but we still check it just in case.
            if (delta + tips.deliveryTip() > type(uint64).max) revert TipsOverflow();
            // Delivery tips occupy lowest 8 bytes, so we can just add delta to the tips value
            // to effectively increase the delivery tip (knowing that delta fits into uint64).
            newTips = Tips.wrap(Tips.unwrap(tips) + delta);
        }
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

/// @notice A collection of events emitted by the GasOracle contract
abstract contract GasOracleEvents {
    /**
     * @notice Emitted when gas data is updated for the domain
     * @param domain        Domain of chain the gas data is for
     * @param paddedGasData Padded encoded gas data
     */
    event GasDataUpdated(uint32 domain, uint256 paddedGasData);
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

interface InterfaceGasOracle {
    /**
     * @notice Fetches the latest gas data for the chain from `Destination` contract,
     * and uses it to update the oracle values for the requested chain.
     * @param domain    Domain to update the gas data for
     */
    function updateGasData(uint32 domain) external;

    /**
     * @notice Returns the gas data for the local chain.
     */
    function getGasData() external view returns (uint256 paddedGasData);

    /**
     * @notice Returns the gas data for the given domain, in the decoded format.
     * @param domain        Domain of chain to get gas data for
     * @return gasPrice     Gas price for the chain (in Wei per gas unit)
     * @return dataPrice    Calldata price (in Wei per byte of content)
     * @return execBuffer   Tx fee safety buffer for message execution (in Wei)
     * @return amortAttCost Amortized cost for attestation submission (in Wei)
     * @return etherPrice   Ratio of Chain's Ether Price / Mainnet Ether Price (in BWAD)
     * @return markup       Markup for the message execution (in BWAD)
     */
    function getDecodedGasData(uint32 domain)
        external
        view
        returns (
            uint256 gasPrice,
            uint256 dataPrice,
            uint256 execBuffer,
            uint256 amortAttCost,
            uint256 etherPrice,
            uint256 markup
        );

    /**
     * @notice Returns the minimum tips for sending a message to a given destination.
     * @param destination       Domain of destination chain
     * @param paddedRequest     Padded encoded message execution request on destination chain
     * @param contentLength     The length of the message content
     * @return paddedTips       Padded encoded minimum tips information
     */
    function getMinimumTips(uint32 destination, uint256 paddedRequest, uint256 contentLength)
        external
        view
        returns (uint256 paddedTips);
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