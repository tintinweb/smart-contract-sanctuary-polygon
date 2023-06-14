// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// ══════════════════════════════ LIBRARY IMPORTS ══════════════════════════════
import {TypeCasts} from "../libs/TypeCasts.sol";
// ═════════════════════════════ INTERNAL IMPORTS ══════════════════════════════
import {MessageRecipient} from "./MessageRecipient.sol";

contract PingPongClient is MessageRecipient {
    using TypeCasts for address;

    struct PingPongMessage {
        uint256 pingId;
        bool isPing;
        uint16 counter;
    }

    // ══════════════════════════════════════════════════ STORAGE ══════════════════════════════════════════════════════

    uint256 public random;

    /// @notice Amount of "Ping" messages sent.
    uint256 public pingsSent;

    /// @notice Amount of "Ping" messages received.
    /// Every received Ping message leads to sending a Pong message back to initial sender.
    uint256 public pingsReceived;

    /// @notice Amount of "Pong" messages received.
    /// When all messages are delivered, should be equal to `pingsSent`
    uint256 public pongsReceived;

    // ══════════════════════════════════════════════════ EVENTS ═══════════════════════════════════════════════════════

    /// @notice Emitted when a Ping message is sent.
    /// Triggered externally, or by receveing a Pong message with instructions to do more pings.
    event PingSent(uint256 pingId);

    /// @notice Emitted when a Ping message is received.
    /// Will always send a Pong message back.
    event PingReceived(uint256 pingId);

    /// @notice Emitted when a Pong message is sent.
    /// Triggered whenever a Ping message is received.
    event PongSent(uint256 pingId);

    /// @notice Emitted when a Pong message is received.
    /// Will initiate a new Ping, if the counter in the message is non-zero.
    event PongReceived(uint256 pingId);

    // ════════════════════════════════════════════════ CONSTRUCTOR ════════════════════════════════════════════════════

    constructor(address origin_, address destination_) MessageRecipient(origin_, destination_) {
        // Initiate "random" value
        random = uint256(keccak256(abi.encode(block.number)));
    }

    // ═══════════════════════════════════════════════ MESSAGE LOGIC ═══════════════════════════════════════════════════

    function doPings(uint16 pingCount, uint32 destination_, address recipient, uint16 counter) external {
        for (uint256 i = 0; i < pingCount; ++i) {
            _ping(destination_, recipient.addressToBytes32(), counter);
        }
    }

    /// @notice Send a Ping message to destination chain.
    /// Upon receiving a Ping, a Pong message will be sent back.
    /// If `counter > 0`, this process will be repeated when the Pong message is received.
    /// @param destination_ Chain to send Ping message to
    /// @param recipient    Recipient of Ping message
    /// @param counter      Additional amount of Ping-Pong rounds to conclude
    function doPing(uint32 destination_, address recipient, uint16 counter) external {
        _ping(destination_, recipient.addressToBytes32(), counter);
    }

    // ═══════════════════════════════════════════════════ VIEWS ═══════════════════════════════════════════════════════

    function nextOptimisticPeriod() public view returns (uint32 period) {
        // Use random optimistic period up to one minute
        return uint32(random % 1 minutes);
    }

    // ═════════════════════════════════════ INTERNAL LOGIC: RECEIVE MESSAGES ══════════════════════════════════════════

    /// @inheritdoc MessageRecipient
    function _receiveBaseMessageUnsafe(uint32 origin_, uint32, bytes32 sender, uint256, uint32, bytes memory content)
        internal
        override
    {
        PingPongMessage memory message = abi.decode(content, (PingPongMessage));
        if (message.isPing) {
            // Ping is received
            ++pingsReceived;
            emit PingReceived(message.pingId);
            // Send Pong back
            _pong(origin_, sender, message);
        } else {
            // Pong is received
            ++pongsReceived;
            emit PongReceived(message.pingId);
            // Send extra ping, if initially requested
            if (message.counter != 0) {
                _ping(origin_, sender, message.counter - 1);
            }
        }
    }

    // ═══════════════════════════════════════ INTERNAL LOGIC: SEND MESSAGES ═══════════════════════════════════════════

    /// @dev Returns a random optimistic period value from 0 to 59 seconds.
    function _optimisticPeriod() internal returns (uint32 period) {
        // Use random optimistic period up to one minute
        period = nextOptimisticPeriod();
        // Adjust "random" value
        random = uint256(keccak256(abi.encode(random)));
    }

    /**
     * @dev Send a "Ping" or "Pong" message.
     * @param destination_  Domain of destination chain
     * @param recipient     Message recipient on destination chain
     * @param message   Ping-pong message
     */
    function _sendMessage(uint32 destination_, bytes32 recipient, PingPongMessage memory message) internal {
        // TODO: this probably shouldn't be hardcoded
        MessageRequest memory request = MessageRequest({gasDrop: 0, gasLimit: 500_000, version: 0});
        bytes memory content = abi.encode(message);
        _sendBaseMessage(destination_, recipient, _optimisticPeriod(), request, content);
    }

    /// @dev Initiate a new Ping-Pong round.
    function _ping(uint32 destination_, bytes32 recipient, uint16 counter) internal {
        uint256 pingId = pingsSent++;
        _sendMessage(destination_, recipient, PingPongMessage({pingId: pingId, isPing: true, counter: counter}));
        emit PingSent(pingId);
    }

    /// @dev Send a Pong message back.
    function _pong(uint32 destination_, bytes32 recipient, PingPongMessage memory message) internal {
        _sendMessage(
            destination_, recipient, PingPongMessage({pingId: message.pingId, isPing: false, counter: message.counter})
        );
        emit PongSent(message.pingId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library TypeCasts {
    // alignment preserving cast
    function addressToBytes32(address addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    // alignment preserving cast
    function bytes32ToAddress(bytes32 buf) internal pure returns (address) {
        return address(uint160(uint256(buf)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// ══════════════════════════════ LIBRARY IMPORTS ══════════════════════════════
import {
    CallerNotDestination,
    IncorrectNonce,
    IncorrectSender,
    IncorrectRecipient,
    ZeroProofMaturity
} from "../libs/Errors.sol";
import {Request, RequestLib} from "../libs/stack/Request.sol";
// ═════════════════════════════ INTERNAL IMPORTS ══════════════════════════════
import {InterfaceOrigin} from "../interfaces/InterfaceOrigin.sol";
import {IMessageRecipient} from "../interfaces/IMessageRecipient.sol";

abstract contract MessageRecipient is IMessageRecipient {
    struct MessageRequest {
        uint96 gasDrop;
        uint64 gasLimit;
        uint32 version;
    }

    /// @notice Local chain Origin: used for sending messages
    address public immutable origin;

    /// @notice Local chain Destination: used for receiving messages
    address public immutable destination;

    constructor(address origin_, address destination_) {
        origin = origin_;
        destination = destination_;
    }

    /// @inheritdoc IMessageRecipient
    function receiveBaseMessage(
        uint32 origin_,
        uint32 nonce,
        bytes32 sender,
        uint256 proofMaturity,
        uint32 version,
        bytes memory content
    ) external payable {
        if (msg.sender != destination) revert CallerNotDestination();
        if (nonce == 0) revert IncorrectNonce();
        if (sender == 0) revert IncorrectSender();
        if (proofMaturity == 0) revert ZeroProofMaturity();
        _receiveBaseMessageUnsafe(origin_, nonce, sender, proofMaturity, version, content);
    }

    /**
     * @dev Child contracts should implement the logic for receiving a Base Message in an "unsafe way".
     * Following checks HAVE been performed:
     *  - receiveBaseMessage() was called by Destination (i.e. this is a legit base message).
     *  - Nonce is not zero.
     *  - Message sender on origin chain is not a zero address.
     *  - Proof maturity is not zero.
     * Following checks HAVE NOT been performed (thus "unsafe"):
     *  - Message sender on origin chain could be anything non-zero at this point.
     *  - Proof maturity could be anything non-zero at this point.
     */
    function _receiveBaseMessageUnsafe(
        uint32 origin_,
        uint32 nonce,
        bytes32 sender,
        uint256 proofMaturity,
        uint32 version,
        bytes memory content
    ) internal virtual;

    /**
     * @dev Sends a message to given destination chain. Full `msg.value` is used to pay for the message tips.
     * `_getMinimumTipsValue()` could be used to calculate the minimum required tips value, and should be also
     * exposed as a public view function to estimate the tips value before sending a message off-chain.
     * This function is not exposed in MessageRecipient, as the message encoding is implemented by the child contract.
     * @param destination_          Domain of the destination chain
     * @param recipient             Address of the recipient on destination chain
     * @param optimisticPeriod      Optimistic period for the message
     * @param request               Message execution request on destination chain
     * @param content               The message content
     */
    function _sendBaseMessage(
        uint32 destination_,
        bytes32 recipient,
        uint32 optimisticPeriod,
        MessageRequest memory request,
        bytes memory content
    ) internal returns (uint32 messageNonce, bytes32 messageHash) {
        if (recipient == 0) revert IncorrectRecipient();
        return InterfaceOrigin(origin).sendBaseMessage{value: msg.value}(
            destination_, recipient, optimisticPeriod, _encodeRequest(request), content
        );
    }

    /**
     * @dev Returns the minimum tips value for sending a message to given destination chain.
     * @param destination_          Domain of the destination chain
     * @param request               Message execution request on destination chain
     * @param contentLength         Length of the message content
     */
    function _getMinimumTipsValue(uint32 destination_, MessageRequest memory request, uint256 contentLength)
        internal
        view
        returns (uint256 tipsValue)
    {
        return InterfaceOrigin(origin).getMinimumTipsValue(destination_, _encodeRequest(request), contentLength);
    }

    /**
     * @dev Encodes a message execution request into format that Origin contract is using.
     * @param request               Message execution request on destination chain
     * @return paddedRequest        Encoded request
     */
    function _encodeRequest(MessageRequest memory request) internal pure returns (uint256 paddedRequest) {
        return Request.unwrap(RequestLib.encodeRequest(request.gasDrop, request.gasLimit, request.version));
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

interface IMessageRecipient {
    /**
     * @notice Message recipient needs to implement this function in order to
     * receive cross-chain messages.
     * @dev Message recipient needs to ensure that merkle proof for the message
     * is at least as old as the optimistic period that the recipient is using.
     * Note: as this point it is checked that the "message optimistic period" has passed,
     * however the period value itself could be anything, and thus could differ from the one
     * that the recipient would like to enforce.
     * @param origin            Domain where message originated
     * @param nonce             Message nonce on the origin domain
     * @param sender            Sender address on origin chain
     * @param proofMaturity     Message's merkle proof age in seconds
     * @param version           Message version specified by sender
     * @param content           Raw bytes content of message
     */
    function receiveBaseMessage(
        uint32 origin,
        uint32 nonce,
        bytes32 sender,
        uint256 proofMaturity,
        uint32 version,
        bytes memory content
    ) external payable;
}