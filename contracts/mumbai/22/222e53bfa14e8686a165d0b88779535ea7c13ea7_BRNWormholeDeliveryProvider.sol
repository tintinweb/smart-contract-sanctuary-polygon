// SPDX-License-Identifier: Apache 2

// Heavily based on https://github.com/wormhole-foundation/wormhole/blob/1a50de38e5dca6f8f254998e843285f61a7d32f2/ethereum/contracts/relayer/deliveryProvider/DeliveryProvider.sol

pragma solidity 0.8.19;

import "openzeppelin-contracts/access/Ownable.sol";

import {IWormhole} from "wormhole-contracts/interfaces/IWormhole.sol";
import "wormhole-contracts/relayer/wormholeRelayer/WormholeRelayerSerde.sol";
import "wormhole-contracts/libraries/relayer/ExecutionParameters.sol";

import "src/library/AddressUtils.sol";
import "./interfaces/IBRNWormholeDeliveryProvider.sol";

contract BRNWormholeDeliveryProvider is IBRNWormholeDeliveryProvider, Ownable {
    using WeiLib for Wei;
    using GasLib for Gas;
    using GasPriceLib for GasPrice;
    using WeiPriceLib for WeiPrice;
    using TargetNativeLib for TargetNative;
    using LocalNativeLib for LocalNative;
    using AddressUtils for address;

    /////////////////////// State ///////////////////////
    IWormhole public immutable wormhole;
    bytes32 public immutable wormholeRelayerAddress;
    IWormholeRelayer public immutable relayer;
    WormholeChainId public immutable chainId;

    // State Related to the oracles.
    mapping(WormholeChainId chainId => GasPrice) public gasPrice;
    mapping(WormholeChainId chainId => WeiPrice) public nativeCurrencyPrice;
    mapping(WormholeChainId chainId => Gas) public deliveyrGasOverhead;
    mapping(WormholeChainId chainId => Wei) public maximumBudget;
    mapping(WormholeChainId chainId => bool) private isWormholeChainSupported;
    mapping(WormholeChainId chainId => bytes32) public brnRelayerProviderAddress;
    mapping(WormholeChainId chainId => AssetConversion) public assetConversionBuffer;

    // State for BRN Accounting
    mapping(WormholeChainId chainId => bytes32) brnTransactionAllocatorAddress;
    mapping(uint256 deliveryVAASequenceNumber => uint256 nativeTokenAmount) public fundsDepositedForRelaying;

    constructor(IWormhole _wormhole, IWormholeRelayer _relayer, address _owner) Ownable(_owner) {
        wormhole = _wormhole;
        relayer = _relayer;
        wormholeRelayerAddress = address(_relayer).toBytes32();
        chainId = WormholeChainId.wrap(_wormhole.chainId());
    }

    /////////////////////// DeliveryProvider Specification ///////////////////////
    function quoteEvmDeliveryPrice(uint16 targetChain, Gas gasLimit, TargetNative receiverValue)
        public
        view
        override
        returns (LocalNative nativePriceQuote, GasPrice targetChainRefundPerUnitGasUnused)
    {
        targetChainRefundPerUnitGasUnused = gasPrice[WormholeChainId.wrap(targetChain)];
        Wei costOfProvidingFullGasLimit = gasLimit.toWei(targetChainRefundPerUnitGasUnused);
        Wei transactionFee = quoteDeliveryOverhead(WormholeChainId.wrap(targetChain))
            + gasLimit.toWei(quoteGasPrice(WormholeChainId.wrap(targetChain)));
        Wei receiverValueCost = quoteAssetCost(WormholeChainId.wrap(targetChain), receiverValue);
        nativePriceQuote =
            (transactionFee.max(costOfProvidingFullGasLimit) + receiverValueCost + wormholeMessageFee()).asLocalNative();
        require(
            receiverValue.asNative() + costOfProvidingFullGasLimit <= maximumBudget[WormholeChainId.wrap(targetChain)],
            "Exceeds maximum budget"
        );
    }

    function quoteDeliveryPrice(uint16 targetChain, TargetNative receiverValue, bytes memory encodedExecutionParams)
        external
        view
        override
        returns (LocalNative nativePriceQuote, bytes memory encodedExecutionInfo)
    {
        ExecutionParamsVersion version = decodeExecutionParamsVersion(encodedExecutionParams);
        if (version != ExecutionParamsVersion.EVM_V1) {
            revert UnsupportedExecutionParamsVersion(uint8(version));
        }

        EvmExecutionParamsV1 memory parsed = decodeEvmExecutionParamsV1(encodedExecutionParams);
        GasPrice targetChainRefundPerUnitGasUnused;
        (nativePriceQuote, targetChainRefundPerUnitGasUnused) =
            quoteEvmDeliveryPrice(targetChain, parsed.gasLimit, receiverValue);
        return (
            nativePriceQuote,
            encodeEvmExecutionInfoV1(EvmExecutionInfoV1(parsed.gasLimit, targetChainRefundPerUnitGasUnused))
        );
    }

    function quoteAssetConversion(uint16 targetChain, LocalNative currentChainAmount)
        external
        view
        override
        returns (TargetNative targetChainAmount)
    {
        return quoteAssetConversion(chainId, WormholeChainId.wrap(targetChain), currentChainAmount);
    }

    //Returns the address on this chain that rewards should be sent to
    function getRewardAddress() public view override returns (address payable) {
        return payable(address(this));
    }

    function getTargetChainAddress(uint16 targetChain) public view override returns (bytes32 deliveryProviderAddress) {
        return brnRelayerProviderAddress[WormholeChainId.wrap(targetChain)];
    }

    function isChainSupported(uint16 targetChain) external view override returns (bool supported) {
        return isWormholeChainSupported[WormholeChainId.wrap(targetChain)];
    }

    /////////////////////// Helpers ///////////////////////
    function quoteAssetConversion(
        WormholeChainId sourceChain,
        WormholeChainId targetChain,
        LocalNative sourceChainAmount
    ) internal view returns (TargetNative targetChainAmount) {
        AssetConversion storage _assetConversion = assetConversionBuffer[targetChain];
        return sourceChainAmount.asNative().convertAsset(
            nativeCurrencyPrice[sourceChain],
            nativeCurrencyPrice[targetChain],
            (_assetConversion.buffer),
            (uint32(_assetConversion.buffer) + _assetConversion.denominator),
            false
        ).asTargetNative();
        // round down
    }

    function wormholeMessageFee() public view returns (Wei) {
        return Wei.wrap(wormhole.messageFee());
    }

    //Returns the delivery overhead fee required to deliver a message to the target chain, denominated in this chain's wei.
    function quoteDeliveryOverhead(WormholeChainId targetChain) public view returns (Wei nativePriceQuote) {
        Gas overhead = deliveyrGasOverhead[targetChain];
        Wei targetFees = overhead.toWei(gasPrice[targetChain]);
        Wei result = assetConversion(targetChain, targetFees, chainId);
        require(result.unwrap() <= type(uint128).max, "Overflow");
        return result;
    }

    //Returns the price of purchasing 1 unit of gas on the target chain, denominated in this chain's wei.
    function quoteGasPrice(WormholeChainId targetChain) public view returns (GasPrice) {
        Wei gasPriceInSourceChainCurrency = assetConversion(targetChain, gasPrice[targetChain].priceAsWei(), chainId);
        require(gasPriceInSourceChainCurrency.unwrap() <= type(uint88).max, "Overflow");
        return GasPrice.wrap(uint88(gasPriceInSourceChainCurrency.unwrap()));
    }

    // relevant for chains that have dynamic execution pricing (e.g. Ethereum)
    function assetConversion(WormholeChainId sourceChain, Wei sourceAmount, WormholeChainId targetChain)
        internal
        view
        returns (Wei targetAmount)
    {
        return sourceAmount.convertAsset(
            nativeCurrencyPrice[sourceChain],
            nativeCurrencyPrice[targetChain],
            1,
            1,
            // round up
            true
        );
    }

    function quoteAssetCost(WormholeChainId targetChain, TargetNative targetChainAmount)
        internal
        view
        returns (Wei currentChainAmount)
    {
        AssetConversion storage _assetConversion = assetConversionBuffer[targetChain];
        return targetChainAmount.asNative().convertAsset(
            nativeCurrencyPrice[chainId],
            nativeCurrencyPrice[targetChain],
            (uint32(_assetConversion.buffer) + _assetConversion.denominator),
            (_assetConversion.buffer),
            // round up
            true
        );
    }

    /////////////////////// BRN Fee Accounting ///////////////////////
    receive() external payable {
        if (msg.sender != address(relayer)) {
            revert CallerMustBeWormholeRelayer();
        }

        if (msg.value == 0) {
            revert NoFunds();
        }

        // The sequnce number can correspond to a delivery VAA or a re-delivery VAA
        uint256 deliveryVAASequenceNumber = wormhole.nextSequence(address(relayer)) - 1;
        fundsDepositedForRelaying[deliveryVAASequenceNumber] += msg.value;

        emit FundsDepositedForRelaying(deliveryVAASequenceNumber, msg.value);
    }

    function claimFee(bytes[] calldata _encodedReceiptVAAs, bytes[][] calldata _encodedRedeliveryVAAs)
        external
        override
    {
        uint256 totalFee;
        uint256 length = _encodedReceiptVAAs.length;

        if (length != _encodedRedeliveryVAAs.length) {
            revert ParamterLengthMismatch();
        }

        for (uint256 i; i != length;) {
            totalFee += _checkClaim(_encodedReceiptVAAs[i], _encodedRedeliveryVAAs[i]);
            unchecked {
                ++i;
            }
        }

        // Send the total fee to the relayer
        (bool status,) = msg.sender.call{value: totalFee}("");
        if (!status) {
            revert NativeTransferFailed();
        }
    }

    function _checkClaim(bytes calldata _encodedReceiptVAA, bytes[] calldata _encodedRedeliveryVAA)
        internal
        returns (uint256)
    {
        IWormhole.VM memory receiptVM = _parseAndVerifyVAA(_encodedReceiptVAA);

        bytes32 targetChainBRNTransactionAllocatorAddress =
            brnTransactionAllocatorAddress[WormholeChainId.wrap(receiptVM.emitterChainId)];

        ReceiptVAAPayload memory payload = abi.decode(receiptVM.payload, (ReceiptVAAPayload));

        if (WormholeChainId.wrap(payload.deliveryVAAKey.chainId) != chainId) {
            revert WormholeDeliveryVAASourceChainMismatch(chainId, WormholeChainId.wrap(payload.deliveryVAAKey.chainId));
        }

        if (receiptVM.emitterAddress != targetChainBRNTransactionAllocatorAddress) {
            revert WormholeReceiptVAAEmitterMismatch(
                targetChainBRNTransactionAllocatorAddress, receiptVM.emitterAddress
            );
        }

        if (payload.relayerAddress != RelayerAddress.wrap(msg.sender)) {
            revert NotAuthorized();
        }

        uint256 amount = fundsDepositedForRelaying[payload.deliveryVAAKey.sequence];
        delete fundsDepositedForRelaying[payload.deliveryVAAKey.sequence];

        emit DeliveryFeeClaimed(payload.deliveryVAAKey.sequence, payload.relayerAddress, amount);

        // Process any re-delivery VAAs
        uint256 redeliveryVAACount = _encodedRedeliveryVAA.length;
        for (uint256 i; i != redeliveryVAACount;) {
            amount += _checkRedeliveryVAAClaim(payload.deliveryVAAKey, _encodedRedeliveryVAA[i], payload.relayerAddress);

            unchecked {
                ++i;
            }
        }

        return amount;
    }

    function _checkRedeliveryVAAClaim(
        VaaKey memory _deliveryInstructionVAAKey,
        bytes calldata _encodedRedeliveryVAA,
        RelayerAddress _relayer
    ) internal returns (uint256) {
        IWormhole.VM memory redeliveryVM = _parseAndVerifyVAA(_encodedRedeliveryVAA);

        if (WormholeChainId.wrap(redeliveryVM.emitterChainId) != chainId) {
            revert WormholeRedeliveryVAAEmitterChainMismatch(chainId, WormholeChainId.wrap(redeliveryVM.emitterChainId));
        }

        if (redeliveryVM.emitterAddress != wormholeRelayerAddress) {
            revert WormholeRedeliveryVAAEmitterMismatch(wormholeRelayerAddress, redeliveryVM.emitterAddress);
        }

        RedeliveryInstruction memory redeliveryPayload =
            WormholeRelayerSerde.decodeRedeliveryInstruction(redeliveryVM.payload);

        if (!_compareVaaKey(_deliveryInstructionVAAKey, redeliveryPayload.deliveryVaaKey)) {
            revert WormholeRedeliveryVAAKeyMismatch(_deliveryInstructionVAAKey, redeliveryPayload.deliveryVaaKey);
        }

        uint256 amount = fundsDepositedForRelaying[redeliveryVM.sequence];
        delete fundsDepositedForRelaying[redeliveryVM.sequence];

        emit RedeliveryFeeClaimed(redeliveryVM.sequence, _relayer, amount);

        return amount;
    }

    function _parseAndVerifyVAA(bytes calldata _encodedVAA) internal view returns (IWormhole.VM memory) {
        (IWormhole.VM memory vm, bool valid, string memory reason) = wormhole.parseAndVerifyVM(_encodedVAA);

        if (!valid) {
            revert WormholeVAAVerificationFailed(reason);
        }

        return vm;
    }

    function _compareVaaKey(VaaKey memory _a, VaaKey memory _b) internal pure returns (bool) {
        return _a.chainId == _b.chainId && _a.emitterAddress == _b.emitterAddress && _a.sequence == _b.sequence;
    }

    /////////////////////// Setters ///////////////////////
    function setGasPrice(WormholeChainId targetChain, GasPrice gasPrice_) external override onlyOwner {
        gasPrice[targetChain] = gasPrice_;
    }

    function setNativeCurrencyPrice(WormholeChainId targetChain, WeiPrice nativeCurrencyPrice_)
        external
        override
        onlyOwner
    {
        nativeCurrencyPrice[targetChain] = nativeCurrencyPrice_;
    }

    function setDeliverGasOverhead(WormholeChainId targetChain, Gas deliverGasOverhead_) external override onlyOwner {
        deliveyrGasOverhead[targetChain] = deliverGasOverhead_;
    }

    function setMaximumBudget(WormholeChainId targetChain, Wei maximumBudget_) external override onlyOwner {
        maximumBudget[targetChain] = maximumBudget_;
    }

    function setIsWormholeChainSupported(WormholeChainId targetChain, bool isWormholeChainSupported_)
        external
        override
        onlyOwner
    {
        isWormholeChainSupported[targetChain] = isWormholeChainSupported_;
    }

    function setBrnRelayerProviderAddress(WormholeChainId targetChain, bytes32 brnRelayerProviderAddress_)
        external
        override
        onlyOwner
    {
        brnRelayerProviderAddress[targetChain] = brnRelayerProviderAddress_;
    }

    function setAssetConversionBuffer(WormholeChainId targetChain, AssetConversion calldata assetConversionBuffer_)
        external
        override
        onlyOwner
    {
        assetConversionBuffer[targetChain] = assetConversionBuffer_;
    }

    function setBrnTransactionAllocatorAddress(WormholeChainId targetChain, bytes32 brnTransactionAllocatorAddress_)
        external
        override
        onlyOwner
    {
        brnTransactionAllocatorAddress[targetChain] = brnTransactionAllocatorAddress_;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.19;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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
}

// contracts/Messages.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

interface IWormhole {
    struct GuardianSet {
        address[] keys;
        uint32 expirationTime;
    }

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
        uint8 guardianIndex;
    }

    struct VM {
        uint8 version;
        uint32 timestamp;
        uint32 nonce;
        uint16 emitterChainId;
        bytes32 emitterAddress;
        uint64 sequence;
        uint8 consistencyLevel;
        bytes payload;

        uint32 guardianSetIndex;
        Signature[] signatures;

        bytes32 hash;
    }

    struct ContractUpgrade {
        bytes32 module;
        uint8 action;
        uint16 chain;

        address newContract;
    }

    struct GuardianSetUpgrade {
        bytes32 module;
        uint8 action;
        uint16 chain;

        GuardianSet newGuardianSet;
        uint32 newGuardianSetIndex;
    }

    struct SetMessageFee {
        bytes32 module;
        uint8 action;
        uint16 chain;

        uint256 messageFee;
    }

    struct TransferFees {
        bytes32 module;
        uint8 action;
        uint16 chain;

        uint256 amount;
        bytes32 recipient;
    }

    struct RecoverChainId {
        bytes32 module;
        uint8 action;

        uint256 evmChainId;
        uint16 newChainId;
    }

    event LogMessagePublished(address indexed sender, uint64 sequence, uint32 nonce, bytes payload, uint8 consistencyLevel);
    event ContractUpgraded(address indexed oldContract, address indexed newContract);
    event GuardianSetAdded(uint32 indexed index);

    function publishMessage(
        uint32 nonce,
        bytes memory payload,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);

    function initialize() external;

    function parseAndVerifyVM(bytes calldata encodedVM) external view returns (VM memory vm, bool valid, string memory reason);

    function verifyVM(VM memory vm) external view returns (bool valid, string memory reason);

    function verifySignatures(bytes32 hash, Signature[] memory signatures, GuardianSet memory guardianSet) external pure returns (bool valid, string memory reason);

    function parseVM(bytes memory encodedVM) external pure returns (VM memory vm);

    function quorum(uint numGuardians) external pure returns (uint numSignaturesRequiredForQuorum);

    function getGuardianSet(uint32 index) external view returns (GuardianSet memory);

    function getCurrentGuardianSetIndex() external view returns (uint32);

    function getGuardianSetExpiry() external view returns (uint32);

    function governanceActionIsConsumed(bytes32 hash) external view returns (bool);

    function isInitialized(address impl) external view returns (bool);

    function chainId() external view returns (uint16);

    function isFork() external view returns (bool);

    function governanceChainId() external view returns (uint16);

    function governanceContract() external view returns (bytes32);

    function messageFee() external view returns (uint256);

    function evmChainId() external view returns (uint256);

    function nextSequence(address emitter) external view returns (uint64);

    function parseContractUpgrade(bytes memory encodedUpgrade) external pure returns (ContractUpgrade memory cu);

    function parseGuardianSetUpgrade(bytes memory encodedUpgrade) external pure returns (GuardianSetUpgrade memory gsu);

    function parseSetMessageFee(bytes memory encodedSetMessageFee) external pure returns (SetMessageFee memory smf);

    function parseTransferFees(bytes memory encodedTransferFees) external pure returns (TransferFees memory tf);

    function parseRecoverChainId(bytes memory encodedRecoverChainId) external pure returns (RecoverChainId memory rci);

    function submitContractUpgrade(bytes memory _vm) external;

    function submitSetMessageFee(bytes memory _vm) external;

    function submitNewGuardianSet(bytes memory _vm) external;

    function submitTransferFees(bytes memory _vm) external;

    function submitRecoverChainId(bytes memory _vm) external;
}

// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.19;

import {
    InvalidPayloadId,
    InvalidPayloadLength,
    InvalidVaaKeyType,
    VaaKey
} from "../../interfaces/relayer/IWormholeRelayerTyped.sol";
import {
    DeliveryOverride,
    DeliveryInstruction,
    RedeliveryInstruction
} from "../../libraries/relayer/RelayerInternalStructs.sol";
import {BytesParsing} from "../../libraries/relayer/BytesParsing.sol";
import "../../interfaces/relayer/TypedUnits.sol";

library WormholeRelayerSerde {
    using BytesParsing for bytes;
    using WeiLib for Wei;
    using GasLib for Gas;

    //The slightly subtle difference between `PAYLOAD_ID`s and `VERSION`s is that payload ids carry
    //  both type information _and_ version information, while `VERSION`s only carry the latter.
    //That is, when deserialing a "version struct" we already know the expected type, but since we
    //  publish both Delivery _and_ Redelivery instructions as serialized messages, we need a robust
    //  way to distinguish both their type and their version during deserialization.
    uint8 private constant VERSION_VAAKEY = 1;
    uint8 private constant VERSION_DELIVERY_OVERRIDE = 1;
    uint8 private constant PAYLOAD_ID_DELIVERY_INSTRUCTION = 1;
    uint8 private constant PAYLOAD_ID_REDELIVERY_INSTRUCTION = 2;

    // ---------------------- "public" (i.e implicitly internal) encode/decode -----------------------

    //TODO GAS OPTIMIZATION: All the recursive abi.encodePacked calls in here are _insanely_ gas
    //    inefficient (unless the optimizer is smart enough to just concatenate them tail-recursion
    //    style which seems highly unlikely)

    function encode(DeliveryInstruction memory strct)
        internal
        pure
        returns (bytes memory encoded)
    {
        encoded = abi.encodePacked(
            PAYLOAD_ID_DELIVERY_INSTRUCTION,
            strct.targetChain,
            strct.targetAddress,
            encodeBytes(strct.payload),
            strct.requestedReceiverValue,
            strct.extraReceiverValue
        );
        encoded = abi.encodePacked(
            encoded,
            encodeBytes(strct.encodedExecutionInfo),
            strct.refundChain,
            strct.refundAddress,
            strct.refundDeliveryProvider,
            strct.sourceDeliveryProvider,
            strct.senderAddress,
            encodeVaaKeyArray(strct.vaaKeys)
        );
    }

    function decodeDeliveryInstruction(bytes memory encoded)
        internal
        pure
        returns (DeliveryInstruction memory strct)
    {
        uint256 offset = checkUint8(encoded, 0, PAYLOAD_ID_DELIVERY_INSTRUCTION);

        uint256 requestedReceiverValue;
        uint256 extraReceiverValue;

        (strct.targetChain, offset) = encoded.asUint16Unchecked(offset);
        (strct.targetAddress, offset) = encoded.asBytes32Unchecked(offset);
        (strct.payload, offset) = decodeBytes(encoded, offset);
        (requestedReceiverValue, offset) = encoded.asUint256Unchecked(offset);
        (extraReceiverValue, offset) = encoded.asUint256Unchecked(offset);
        (strct.encodedExecutionInfo, offset) = decodeBytes(encoded, offset);
        (strct.refundChain, offset) = encoded.asUint16Unchecked(offset);
        (strct.refundAddress, offset) = encoded.asBytes32Unchecked(offset);
        (strct.refundDeliveryProvider, offset) = encoded.asBytes32Unchecked(offset);
        (strct.sourceDeliveryProvider, offset) = encoded.asBytes32Unchecked(offset);
        (strct.senderAddress, offset) = encoded.asBytes32Unchecked(offset);
        (strct.vaaKeys, offset) = decodeVaaKeyArray(encoded, offset);

        strct.requestedReceiverValue = TargetNative.wrap(requestedReceiverValue);
        strct.extraReceiverValue = TargetNative.wrap(extraReceiverValue);

        checkLength(encoded, offset);
    }

    function encode(RedeliveryInstruction memory strct)
        internal
        pure
        returns (bytes memory encoded)
    {
        bytes memory vaaKey = encodeVaaKey(strct.deliveryVaaKey);
        encoded = abi.encodePacked(
            PAYLOAD_ID_REDELIVERY_INSTRUCTION,
            vaaKey,
            strct.targetChain,
            strct.newRequestedReceiverValue,
            encodeBytes(strct.newEncodedExecutionInfo),
            strct.newSourceDeliveryProvider,
            strct.newSenderAddress
        );
    }

    function decodeRedeliveryInstruction(bytes memory encoded)
        internal
        pure
        returns (RedeliveryInstruction memory strct)
    {
        uint256 offset = checkUint8(encoded, 0, PAYLOAD_ID_REDELIVERY_INSTRUCTION);

        uint256 newRequestedReceiverValue;

        (strct.deliveryVaaKey, offset) = decodeVaaKey(encoded, offset);
        (strct.targetChain, offset) = encoded.asUint16Unchecked(offset);
        (newRequestedReceiverValue, offset) = encoded.asUint256Unchecked(offset);
        (strct.newEncodedExecutionInfo, offset) = decodeBytes(encoded, offset);
        (strct.newSourceDeliveryProvider, offset) = encoded.asBytes32Unchecked(offset);
        (strct.newSenderAddress, offset) = encoded.asBytes32Unchecked(offset);

        strct.newRequestedReceiverValue = TargetNative.wrap(newRequestedReceiverValue);

        checkLength(encoded, offset);
    }

    function encode(DeliveryOverride memory strct) internal pure returns (bytes memory encoded) {
        encoded = abi.encodePacked(
            VERSION_DELIVERY_OVERRIDE,
            strct.newReceiverValue,
            encodeBytes(strct.newExecutionInfo),
            strct.redeliveryHash
        );
    }

    function decodeDeliveryOverride(bytes memory encoded)
        internal
        pure
        returns (DeliveryOverride memory strct)
    {
        uint256 offset = checkUint8(encoded, 0, VERSION_DELIVERY_OVERRIDE);

        uint256 receiverValue;

        (receiverValue, offset) = encoded.asUint256Unchecked(offset);
        (strct.newExecutionInfo, offset) = decodeBytes(encoded, offset);
        (strct.redeliveryHash, offset) = encoded.asBytes32Unchecked(offset);

        strct.newReceiverValue = TargetNative.wrap(receiverValue);

        checkLength(encoded, offset);
    }

    // ------------------------------------------ private --------------------------------------------

    function encodeVaaKeyArray(VaaKey[] memory vaaKeys)
        private
        pure
        returns (bytes memory encoded)
    {
        assert(vaaKeys.length < type(uint8).max);
        encoded = abi.encodePacked(uint8(vaaKeys.length));
        for (uint256 i = 0; i < vaaKeys.length;) {
            encoded = abi.encodePacked(encoded, encodeVaaKey(vaaKeys[i]));
            unchecked {
                ++i;
            }
        }
    }

    function decodeVaaKeyArray(
        bytes memory encoded,
        uint256 startOffset
    ) private pure returns (VaaKey[] memory vaaKeys, uint256 offset) {
        uint8 vaaKeysLength;
        (vaaKeysLength, offset) = encoded.asUint8Unchecked(startOffset);
        vaaKeys = new VaaKey[](vaaKeysLength);
        for (uint256 i = 0; i < vaaKeys.length;) {
            (vaaKeys[i], offset) = decodeVaaKey(encoded, offset);
            unchecked {
                ++i;
            }
        }
    }

    function encodeVaaKey(VaaKey memory vaaKey) private pure returns (bytes memory encoded) {
        encoded = abi.encodePacked(
            encoded, VERSION_VAAKEY, vaaKey.chainId, vaaKey.emitterAddress, vaaKey.sequence
        );
    }

    function decodeVaaKey(
        bytes memory encoded,
        uint256 startOffset
    ) private pure returns (VaaKey memory vaaKey, uint256 offset) {
        offset = checkUint8(encoded, startOffset, VERSION_VAAKEY);
        (vaaKey.chainId, offset) = encoded.asUint16Unchecked(offset);
        (vaaKey.emitterAddress, offset) = encoded.asBytes32Unchecked(offset);
        (vaaKey.sequence, offset) = encoded.asUint64Unchecked(offset);
    }

    function encodeBytes(bytes memory payload) private pure returns (bytes memory encoded) {
        //casting payload.length to uint32 is safe because you'll be hard-pressed to allocate 4 GB of
        //  EVM memory in a single transaction
        encoded = abi.encodePacked(uint32(payload.length), payload);
    }

    function decodeBytes(
        bytes memory encoded,
        uint256 startOffset
    ) private pure returns (bytes memory payload, uint256 offset) {
        uint32 payloadLength;
        (payloadLength, offset) = encoded.asUint32Unchecked(startOffset);
        (payload, offset) = encoded.sliceUnchecked(offset, payloadLength);
    }

    function checkUint8(
        bytes memory encoded,
        uint256 startOffset,
        uint8 expectedPayloadId
    ) private pure returns (uint256 offset) {
        uint8 parsedPayloadId;
        (parsedPayloadId, offset) = encoded.asUint8Unchecked(startOffset);
        if (parsedPayloadId != expectedPayloadId) {
            revert InvalidPayloadId(parsedPayloadId, expectedPayloadId);
        }
    }

    function checkLength(bytes memory encoded, uint256 expected) private pure {
        if (encoded.length != expected) {
            revert InvalidPayloadLength(encoded.length, expected);
        }
    }
}

// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.19;

import "../../interfaces/relayer/TypedUnits.sol";
import {BytesParsing} from "../../libraries/relayer/BytesParsing.sol";

error UnexpectedExecutionParamsVersion(uint8 version, uint8 expectedVersion);
error UnsupportedExecutionParamsVersion(uint8 version);
error TargetChainAndExecutionParamsVersionMismatch(uint16 targetChain, uint8 version);
error UnexpectedExecutionInfoVersion(uint8 version, uint8 expectedVersion);
error UnsupportedExecutionInfoVersion(uint8 version);
error TargetChainAndExecutionInfoVersionMismatch(uint16 targetChain, uint8 version);
error VersionMismatchOverride(uint8 instructionVersion, uint8 overrideVersion);

using BytesParsing for bytes;

enum ExecutionParamsVersion {EVM_V1}

struct EvmExecutionParamsV1 {
    Gas gasLimit;
}

enum ExecutionInfoVersion {EVM_V1}

struct EvmExecutionInfoV1 {
    Gas gasLimit;
    GasPrice targetChainRefundPerGasUnused;
}

function decodeExecutionParamsVersion(bytes memory data)
    pure
    returns (ExecutionParamsVersion version)
{
    (version) = abi.decode(data, (ExecutionParamsVersion));
}

function decodeExecutionInfoVersion(bytes memory data)
    pure
    returns (ExecutionInfoVersion version)
{
    (version) = abi.decode(data, (ExecutionInfoVersion));
}

function encodeEvmExecutionParamsV1(EvmExecutionParamsV1 memory executionParams)
    pure
    returns (bytes memory)
{
    return abi.encode(uint8(ExecutionParamsVersion.EVM_V1), executionParams.gasLimit);
}

function decodeEvmExecutionParamsV1(bytes memory data)
    pure
    returns (EvmExecutionParamsV1 memory executionParams)
{
    uint8 version;
    (version, executionParams.gasLimit) = abi.decode(data, (uint8, Gas));

    if (version != uint8(ExecutionParamsVersion.EVM_V1)) {
        revert UnexpectedExecutionParamsVersion(version, uint8(ExecutionParamsVersion.EVM_V1));
    }
}

function encodeEvmExecutionInfoV1(EvmExecutionInfoV1 memory executionInfo)
    pure
    returns (bytes memory)
{
    return abi.encode(
        uint8(ExecutionInfoVersion.EVM_V1),
        executionInfo.gasLimit,
        executionInfo.targetChainRefundPerGasUnused
    );
}

function decodeEvmExecutionInfoV1(bytes memory data)
    pure
    returns (EvmExecutionInfoV1 memory executionInfo)
{
    uint8 version;
    (version, executionInfo.gasLimit, executionInfo.targetChainRefundPerGasUnused) =
        abi.decode(data, (uint8, Gas, GasPrice));

    if (version != uint8(ExecutionInfoVersion.EVM_V1)) {
        revert UnexpectedExecutionInfoVersion(version, uint8(ExecutionInfoVersion.EVM_V1));
    }
}

function getEmptyEvmExecutionParamsV1()
    pure
    returns (EvmExecutionParamsV1 memory executionParams)
{
    executionParams.gasLimit = Gas.wrap(uint256(0));
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

library AddressUtils {
    function toBytes32(address a) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(a)));
    }

    function toAddress(bytes32 b) internal pure returns (address) {
        return address(uint160(uint256(b)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IDeliveryProvider} from "wormhole-contracts/interfaces/relayer/IDeliveryProviderTyped.sol";

import "./IBRNWormholeDeliveryProviderEventsErrors.sol";
import "./WormholeTypes.sol";

interface IBRNWormholeDeliveryProvider is IDeliveryProvider, IBRNWormholeDeliveryProviderEventsErrors {
    struct AssetConversion {
        // The following two fields are a percentage buffer that is used to upcharge the user for the value attached to the message sent.
        // The cost of getting ‘targetAmount’ on the target chain for the receiverValue is
        // (denominator + buffer) / (denominator) * (the converted amount in source chain currency using the ‘quoteAssetPrice’ values)
        uint16 buffer;
        uint16 denominator;
    }

    function quoteEvmDeliveryPrice(uint16 targetChain, Gas gasLimit, TargetNative receiverValue)
        external
        returns (LocalNative nativePriceQuote, GasPrice targetChainRefundPerUnitGasUnused);

    function claimFee(bytes[] calldata _encodedReceiptVAAs, bytes[][] calldata _encodedRedeliveryVAAs) external;

    /////////////////////// Setters ///////////////////////
    function setGasPrice(WormholeChainId targetChain, GasPrice gasPrice_) external;

    function setNativeCurrencyPrice(WormholeChainId targetChain, WeiPrice nativeCurrencyPrice_) external;

    function setDeliverGasOverhead(WormholeChainId targetChain, Gas deliverGasOverhead_) external;

    function setMaximumBudget(WormholeChainId targetChain, Wei maximumBudget_) external;

    function setIsWormholeChainSupported(WormholeChainId targetChain, bool isWormholeChainSupported_) external;

    function setBrnRelayerProviderAddress(WormholeChainId targetChain, bytes32 brnRelayerProviderAddress_) external;

    function setAssetConversionBuffer(WormholeChainId targetChain, AssetConversion calldata assetConversionBuffer_)
        external;

    function setBrnTransactionAllocatorAddress(WormholeChainId targetChain, bytes32 brnTransactionAllocatorAddress_)
        external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.19;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.19;

import "./TypedUnits.sol";

/**
 * @notice VaaKey identifies a wormhole message
 *
 * @custom:member chainId - only specified if `infoType == VaaKeyType.EMITTER_SEQUENCE`
 * @custom:member emitterAddress - only specified if `infoType = VaaKeyType.EMITTER_SEQUENCE`
 * @custom:member sequence - only specified if `infoType = VaaKeyType.EMITTER_SEQUENCE`
 */
struct VaaKey {
    uint16 chainId;
    bytes32 emitterAddress;
    uint64 sequence;
}

interface IWormholeRelayerBase {
    event SendEvent(
        uint64 indexed sequence, LocalNative deliveryQuote, LocalNative paymentForExtraReceiverValue
    );

    function getRegisteredWormholeRelayerContract(uint16 chainId) external view returns (bytes32);
}

/**
 * IWormholeRelayer
 * @notice Users may use this interface to have payloads and/or wormhole VAAs
 *   relayed to destination contract(s) of their choice.
 */
interface IWormholeRelayerSend is IWormholeRelayerBase {
    function sendPayloadToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        TargetNative receiverValue,
        Gas gasLimit
    ) external payable returns (uint64 sequence);

    function sendPayloadToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        TargetNative receiverValue,
        Gas gasLimit,
        uint16 refundChain,
        address refundAddress
    ) external payable returns (uint64 sequence);

    function sendVaasToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        TargetNative receiverValue,
        Gas gasLimit,
        VaaKey[] memory vaaKeys
    ) external payable returns (uint64 sequence);

    function sendVaasToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        TargetNative receiverValue,
        Gas gasLimit,
        VaaKey[] memory vaaKeys,
        uint16 refundChain,
        address refundAddress
    ) external payable returns (uint64 sequence);

    function sendToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        TargetNative receiverValue,
        LocalNative paymentForExtraReceiverValue,
        Gas gasLimit,
        uint16 refundChain,
        address refundAddress,
        address deliveryProviderAddress,
        VaaKey[] memory vaaKeys,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);

    function send(
        uint16 targetChain,
        bytes32 targetAddress,
        bytes memory payload,
        TargetNative receiverValue,
        LocalNative paymentForExtraReceiverValue,
        bytes memory encodedExecutionParameters,
        uint16 refundChain,
        bytes32 refundAddress,
        address deliveryProviderAddress,
        VaaKey[] memory vaaKeys,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);

    function forwardPayloadToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        TargetNative receiverValue,
        Gas gasLimit
    ) external payable;

    function forwardVaasToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        TargetNative receiverValue,
        Gas gasLimit,
        VaaKey[] memory vaaKeys
    ) external payable;

    function forwardToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        TargetNative receiverValue,
        LocalNative paymentForExtraReceiverValue,
        Gas gasLimit,
        uint16 refundChain,
        address refundAddress,
        address deliveryProviderAddress,
        VaaKey[] memory vaaKeys,
        uint8 consistencyLevel
    ) external payable;

    function forward(
        uint16 targetChain,
        bytes32 targetAddress,
        bytes memory payload,
        TargetNative receiverValue,
        LocalNative paymentForExtraReceiverValue,
        bytes memory encodedExecutionParameters,
        uint16 refundChain,
        bytes32 refundAddress,
        address deliveryProviderAddress,
        VaaKey[] memory vaaKeys,
        uint8 consistencyLevel
    ) external payable;

    function resendToEvm(
        VaaKey memory deliveryVaaKey,
        uint16 targetChain,
        TargetNative newReceiverValue,
        Gas newGasLimit,
        address newDeliveryProviderAddress
    ) external payable returns (uint64 sequence);

    function resend(
        VaaKey memory deliveryVaaKey,
        uint16 targetChain,
        TargetNative newReceiverValue,
        bytes memory newEncodedExecutionParameters,
        address newDeliveryProviderAddress
    ) external payable returns (uint64 sequence);

    function quoteEVMDeliveryPrice(
        uint16 targetChain,
        TargetNative receiverValue,
        Gas gasLimit
    ) external view returns (LocalNative nativePriceQuote, GasPrice targetChainRefundPerGasUnused);

    function quoteEVMDeliveryPrice(
        uint16 targetChain,
        TargetNative receiverValue,
        Gas gasLimit,
        address deliveryProviderAddress
    ) external view returns (LocalNative nativePriceQuote, GasPrice targetChainRefundPerGasUnused);

    function quoteDeliveryPrice(
        uint16 targetChain,
        TargetNative receiverValue,
        bytes memory encodedExecutionParameters,
        address deliveryProviderAddress
    ) external view returns (LocalNative nativePriceQuote, bytes memory encodedExecutionInfo);

    function quoteNativeForChain(
        uint16 targetChain,
        LocalNative currentChainAmount,
        address deliveryProviderAddress
    ) external view returns (TargetNative targetChainAmount);

    /**
     * @notice Returns the address of the current default delivery provider
     * @return deliveryProvider The address of (the default delivery provider)'s contract on this source
     *   chain. This must be a contract that implements IDeliveryProvider.
     */
    function getDefaultDeliveryProvider() external view returns (address deliveryProvider);
}

interface IWormholeRelayerDelivery is IWormholeRelayerBase {
    enum DeliveryStatus {
        SUCCESS,
        RECEIVER_FAILURE,
        FORWARD_REQUEST_FAILURE,
        FORWARD_REQUEST_SUCCESS
    }

    enum RefundStatus {
        REFUND_SENT,
        REFUND_FAIL,
        CROSS_CHAIN_REFUND_SENT,
        CROSS_CHAIN_REFUND_FAIL_PROVIDER_NOT_SUPPORTED,
        CROSS_CHAIN_REFUND_FAIL_NOT_ENOUGH
    }

    /**
     * @custom:member recipientContract - The target contract address
     * @custom:member sourceChain - The chain which this delivery was requested from (in wormhole
     *     ChainID format)
     * @custom:member sequence - The wormhole sequence number of the delivery VAA on the source chain
     *     corresponding to this delivery request
     * @custom:member deliveryVaaHash - The hash of the delivery VAA corresponding to this delivery
     *     request
     * @custom:member gasUsed - The amount of gas that was used to call your target contract (and, if
     *     there was a forward, to ensure that there were enough funds to complete the forward)
     * @custom:member status:
     *   - RECEIVER_FAILURE, if the target contract reverts
     *   - SUCCESS, if the target contract doesn't revert and no forwards were requested
     *   - FORWARD_REQUEST_FAILURE, if the target contract doesn't revert, forwards were requested,
     *       but provided/leftover funds were not sufficient to cover them all
     *   - FORWARD_REQUEST_SUCCESS, if the target contract doesn't revert and all forwards are covered
     * @custom:member additionalStatusInfo:
     *   - If status is SUCCESS or FORWARD_REQUEST_SUCCESS, then this is empty.
     *   - If status is RECEIVER_FAILURE, this is `RETURNDATA_TRUNCATION_THRESHOLD` bytes of the
     *       return data (i.e. potentially truncated revert reason information).
     *   - If status is FORWARD_REQUEST_FAILURE, this is also the revert data - the reason the forward failed.
     *     This will be either an encoded Cancelled, DeliveryProviderReverted, or DeliveryProviderPaymentFailed error
     * @custom:member refundStatus - Result of the refund. REFUND_SUCCESS or REFUND_FAIL are for
     *     refunds where targetChain=refundChain; the others are for targetChain!=refundChain,
     *     where a cross chain refund is necessary
     * @custom:member overridesInfo:
     *   - If not an override: empty bytes array
     *   - Otherwise: An encoded `DeliveryOverride`
     */
    event Delivery(
        address indexed recipientContract,
        uint16 indexed sourceChain,
        uint64 indexed sequence,
        bytes32 deliveryVaaHash,
        DeliveryStatus status,
        Gas gasUsed,
        RefundStatus refundStatus,
        bytes additionalStatusInfo,
        bytes overridesInfo
    );

    /**
     * @notice The relay provider calls `deliver` to relay messages as described by one delivery instruction
     * 
     * The relay provider must pass in the specified (by VaaKeys[]) signed wormhole messages (VAAs) from the source chain
     * as well as the signed wormhole message with the delivery instructions (the delivery VAA)
     *
     * The messages will be relayed to the target address (with the specified gas limit and receiver value) iff the following checks are met:
     * - the delivery VAA has a valid signature
     * - the delivery VAA's emitter is one of these WormholeRelayer contracts
     * - the delivery instruction container in the delivery VAA was fully funded
     * - msg.sender is the permissioned address allowed to execute this instruction
     * - the relay provider passed in at least enough of this chain's currency as msg.value (enough meaning the maximum possible refund)     * - the instruction's target chain is this chain
     * - the relayed signed VAAs match the descriptions in container.messages (the VAA hashes match, or the emitter address, sequence number pair matches, depending on the description given)
     *
     * @param encodedVMs - An array of signed wormhole messages (all from the same source chain
     *     transaction)
     * @param encodedDeliveryVAA - Signed wormhole message from the source chain's WormholeRelayer
     *     contract with payload being the encoded delivery instruction container
     * @param relayerRefundAddress - The address to which any refunds to the delivery provider
     *     should be sent
     * @param deliveryOverrides - Optional overrides field which must be either an empty bytes array or
     *     an encoded DeliveryOverride struct
     */
    function deliver(
        bytes[] memory encodedVMs,
        bytes memory encodedDeliveryVAA,
        address payable relayerRefundAddress,
        bytes memory deliveryOverrides
    ) external payable;
}

interface IWormholeRelayer is IWormholeRelayerDelivery, IWormholeRelayerSend {}

/*
 *  Errors thrown by IWormholeRelayer contract
 */

// Bound chosen by the following formula: `memoryWord * 4 + selectorSize`.
// This means that an error identifier plus four fixed size arguments should be available to developers.
// In the case of a `require` revert with error message, this should provide 2 memory word's worth of data.
uint256 constant RETURNDATA_TRUNCATION_THRESHOLD = 132;

//When msg.value was not equal to (one wormhole message fee) + `maxTransactionFee` + `receiverValue`
error InvalidMsgValue(LocalNative msgValue, LocalNative totalFee);

error RequestedGasLimitTooLow();

error DeliveryProviderDoesNotSupportTargetChain(address relayer, uint16 chainId);
error DeliveryProviderCannotReceivePayment();

//When calling `forward()` on the WormholeRelayer if no delivery is in progress
error NoDeliveryInProgress();
//When calling `delivery()` a second time even though a delivery is already in progress
error ReentrantDelivery(address msgSender, address lockedBy);
//When any other contract but the delivery target calls `forward()` on the WormholeRelayer while a
//  delivery is in progress
error ForwardRequestFromWrongAddress(address msgSender, address deliveryTarget);

error InvalidPayloadId(uint8 parsed, uint8 expected);
error InvalidPayloadLength(uint256 received, uint256 expected);
error InvalidVaaKeyType(uint8 parsed);

error InvalidDeliveryVaa(string reason);
//When the delivery VAA (signed wormhole message with delivery instructions) was not emitted by the
//  registered WormholeRelayer contract
error InvalidEmitter(bytes32 emitter, bytes32 registered, uint16 chainId);
error VaaKeysLengthDoesNotMatchVaasLength(uint256 keys, uint256 vaas);
error VaaKeysDoNotMatchVaas(uint8 index);
//When someone tries to call an external function of the WormholeRelayer that is only intended to be
//  called by the WormholeRelayer itself (to allow retroactive reverts for atomicity)
error RequesterNotWormholeRelayer();

//When trying to relay a `DeliveryInstruction` to any other chain but the one it was specified for
error TargetChainIsNotThisChain(uint16 targetChain);
error ForwardNotSufficientlyFunded(LocalNative amountOfFunds, LocalNative amountOfFundsNeeded);
//When a `DeliveryOverride` contains a gas limit that's less than the original
error InvalidOverrideGasLimit();
//When a `DeliveryOverride` contains a receiver value that's less than the original
error InvalidOverrideReceiverValue();
//When a `DeliveryOverride` contains a refund per gas unused that's less than the original
error InvalidOverrideRefundPerGasUnused();

//When the relay provider doesn't pass in sufficient funds (i.e. msg.value does not cover the
// maximum possible refund to the user)
error InsufficientRelayerFunds(LocalNative msgValue, LocalNative minimum);

//When a bytes32 field can't be converted into a 20 byte EVM address, because the 12 padding bytes
//  are non-zero (duplicated from Utils.sol)
error NotAnEvmAddress(bytes32);

// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.19;

import "../../interfaces/relayer/TypedUnits.sol";
import "../../interfaces/relayer/IWormholeRelayerTyped.sol";

struct DeliveryInstruction {
    uint16 targetChain;
    bytes32 targetAddress;
    bytes payload;
    TargetNative requestedReceiverValue;
    TargetNative extraReceiverValue;
    bytes encodedExecutionInfo;
    uint16 refundChain;
    bytes32 refundAddress;
    bytes32 refundDeliveryProvider;
    bytes32 sourceDeliveryProvider;
    bytes32 senderAddress;
    VaaKey[] vaaKeys;
}

// Meant to hold all necessary values for `CoreRelayerDelivery::executeInstruction`
// Nothing more and nothing less.
struct EvmDeliveryInstruction {
  uint16 sourceChain;
  bytes32 targetAddress;
  bytes payload;
  Gas gasLimit;
  TargetNative totalReceiverValue;
  GasPrice targetChainRefundPerGasUnused;
  bytes32 senderAddress;
  bytes32 deliveryHash;
  bytes[] signedVaas;
}

struct RedeliveryInstruction {
    VaaKey deliveryVaaKey;
    uint16 targetChain;
    TargetNative newRequestedReceiverValue;
    bytes newEncodedExecutionInfo;
    bytes32 newSourceDeliveryProvider;
    bytes32 newSenderAddress;
}

/**
 * @notice When a user requests a `resend()`, a `RedeliveryInstruction` is emitted by the
 *     WormholeRelayer and in turn converted by the relay provider into an encoded (=serialized)
 *     `DeliveryOverride` struct which is then passed to `delivery()` to override the parameters of
 *     a previously failed delivery attempt.
 *
 * @custom:member newReceiverValue - must >= than the `receiverValue` specified in the original
 *     `DeliveryInstruction`
 * @custom:member newExecutionInfo - for EVM_V1, must contain a gasLimit and targetChainRefundPerGasUnused
 * such that 
 * - gasLimit is >= the `gasLimit` specified in the `executionParameters`
 *     of the original `DeliveryInstruction`
 * - targetChainRefundPerGasUnused is >=  the `targetChainRefundPerGasUnused` specified in the original
 *     `DeliveryInstruction`
 * @custom:member redeliveryHash - the hash of the redelivery which is being performed
 */
struct DeliveryOverride {
    TargetNative newReceiverValue;
    bytes newExecutionInfo;
    bytes32 redeliveryHash;
}

pragma solidity ^0.8.19;

library BytesParsing {
  uint256 private constant freeMemoryPtr = 0x40;
  uint256 private constant wordSize = 32;

  error OutOfBounds(uint256 offset, uint256 length);

  function checkBound(uint offset, uint length) internal pure {
    if (offset > length)
      revert OutOfBounds(offset, length);
  }

  function sliceUnchecked(
    bytes memory encoded,
    uint offset,
    uint length
  ) internal pure returns (bytes memory ret, uint nextOffset) {
    //bail early for degenerate case
    if (length == 0)
      return (new bytes(0), offset);

    assembly ("memory-safe") {
      nextOffset := add(offset, length)
      ret := mload(freeMemoryPtr)

      //Explanation on how we copy data here:
      //  The bytes type has the following layout in memory:
      //    [length: 32 bytes, data: length bytes]
      //  So if we allocate `bytes memory foo = new bytes(1);` then `foo` will be a pointer to 33
      //    bytes where the first 32 bytes contain the length and the last byte is the actual data.
      //  Since mload always loads 32 bytes of memory at once, we use our shift variable to align
      //    our reads so that our last read lines up exactly with the last 32 bytes of `encoded`.
      //  However this also means that if the length of `encoded` is not a multiple of 32 bytes, our
      //    first read will necessarily partly contain bytes from `encoded`'s 32 length bytes that
      //    will be written into the length part of our `ret` slice.
      //  We remedy this issue by writing the length of our `ret` slice at the end, thus
      //    overwritting those garbage bytes.
      let shift := and(length, 31) //equivalent to `mod(length, 32)` but 2 gas cheaper
      if iszero(shift) {
        shift := wordSize
      }

      let dest := add(ret, shift)
      let end := add(dest, length)
      for {
        let src := add(add(encoded, shift), offset)
      } lt(dest, end) {
        src := add(src, wordSize)
        dest := add(dest, wordSize)
      } {
        mstore(dest, mload(src))
      }

      mstore(ret, length)
      //When compiling with --via-ir then normally allocated memory (i.e. via new) will have 32 byte
      //  memory alignment and so we enforce the same memory alignment here.
      mstore(freeMemoryPtr, and(add(dest, 31), not(31)))
    }
  }

  function slice(
    bytes memory encoded,
    uint offset,
    uint length
  ) internal pure returns (bytes memory ret, uint nextOffset) {
    (ret, nextOffset) = sliceUnchecked(encoded, offset, length);
    checkBound(nextOffset, encoded.length);
  }

  function asAddressUnchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (address, uint) {
    (uint160 ret, uint nextOffset) = asUint160(encoded, offset);
    return (address(ret), nextOffset);
  }

  function asAddress(
    bytes memory encoded,
    uint offset
  ) internal pure returns (address ret, uint nextOffset) {
    (ret, nextOffset) = asAddressUnchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBoolUnckecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bool, uint) {
    (uint8 ret, uint nextOffset) = asUint8(encoded, offset);
    return (ret != 0, nextOffset);
  }

  function asBool(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bool ret, uint nextOffset) {
    (ret, nextOffset) = asBoolUnckecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

/* -------------------------------------------------------------------------------------------------
Remaining library code below was auto-generated by via the following js/node code:

for (let bytes = 1; bytes <= 32; ++bytes) {
  const bits = bytes*8;
  console.log(
`function asUint${bits}Unchecked(
  bytes memory encoded,
  uint offset
) internal pure returns (uint${bits} ret, uint nextOffset) {
  assembly ("memory-safe") {
    nextOffset := add(offset, ${bytes})
    ret := mload(add(encoded, nextOffset))
  }
  return (ret, nextOffset);
}

function asUint${bits}(
  bytes memory encoded,
  uint offset
) internal pure returns (uint${bits} ret, uint nextOffset) {
  (ret, nextOffset) = asUint${bits}Unchecked(encoded, offset);
  checkBound(nextOffset, encoded.length);
}

function asBytes${bytes}Unchecked(
  bytes memory encoded,
  uint offset
) internal pure returns (bytes${bytes}, uint) {
  (uint${bits} ret, uint nextOffset) = asUint${bits}Unchecked(encoded, offset);
  return (bytes${bytes}(ret), nextOffset);
}

function asBytes${bytes}(
  bytes memory encoded,
  uint offset
) internal pure returns (bytes${bytes}, uint) {
  (uint${bits} ret, uint nextOffset) = asUint${bits}(encoded, offset);
  return (bytes${bytes}(ret), nextOffset);
}
`
  );
}
------------------------------------------------------------------------------------------------- */

  function asUint8Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint8 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 1)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint8(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint8 ret, uint nextOffset) {
    (ret, nextOffset) = asUint8Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes1Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes1, uint) {
    (uint8 ret, uint nextOffset) = asUint8Unchecked(encoded, offset);
    return (bytes1(ret), nextOffset);
  }

  function asBytes1(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes1, uint) {
    (uint8 ret, uint nextOffset) = asUint8(encoded, offset);
    return (bytes1(ret), nextOffset);
  }

  function asUint16Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint16 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 2)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint16(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint16 ret, uint nextOffset) {
    (ret, nextOffset) = asUint16Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes2Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes2, uint) {
    (uint16 ret, uint nextOffset) = asUint16Unchecked(encoded, offset);
    return (bytes2(ret), nextOffset);
  }

  function asBytes2(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes2, uint) {
    (uint16 ret, uint nextOffset) = asUint16(encoded, offset);
    return (bytes2(ret), nextOffset);
  }

  function asUint24Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint24 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 3)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint24(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint24 ret, uint nextOffset) {
    (ret, nextOffset) = asUint24Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes3Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes3, uint) {
    (uint24 ret, uint nextOffset) = asUint24Unchecked(encoded, offset);
    return (bytes3(ret), nextOffset);
  }

  function asBytes3(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes3, uint) {
    (uint24 ret, uint nextOffset) = asUint24(encoded, offset);
    return (bytes3(ret), nextOffset);
  }

  function asUint32Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint32 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 4)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint32(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint32 ret, uint nextOffset) {
    (ret, nextOffset) = asUint32Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes4Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes4, uint) {
    (uint32 ret, uint nextOffset) = asUint32Unchecked(encoded, offset);
    return (bytes4(ret), nextOffset);
  }

  function asBytes4(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes4, uint) {
    (uint32 ret, uint nextOffset) = asUint32(encoded, offset);
    return (bytes4(ret), nextOffset);
  }

  function asUint40Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint40 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 5)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint40(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint40 ret, uint nextOffset) {
    (ret, nextOffset) = asUint40Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes5Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes5, uint) {
    (uint40 ret, uint nextOffset) = asUint40Unchecked(encoded, offset);
    return (bytes5(ret), nextOffset);
  }

  function asBytes5(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes5, uint) {
    (uint40 ret, uint nextOffset) = asUint40(encoded, offset);
    return (bytes5(ret), nextOffset);
  }

  function asUint48Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint48 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 6)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint48(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint48 ret, uint nextOffset) {
    (ret, nextOffset) = asUint48Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes6Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes6, uint) {
    (uint48 ret, uint nextOffset) = asUint48Unchecked(encoded, offset);
    return (bytes6(ret), nextOffset);
  }

  function asBytes6(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes6, uint) {
    (uint48 ret, uint nextOffset) = asUint48(encoded, offset);
    return (bytes6(ret), nextOffset);
  }

  function asUint56Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint56 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 7)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint56(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint56 ret, uint nextOffset) {
    (ret, nextOffset) = asUint56Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes7Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes7, uint) {
    (uint56 ret, uint nextOffset) = asUint56Unchecked(encoded, offset);
    return (bytes7(ret), nextOffset);
  }

  function asBytes7(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes7, uint) {
    (uint56 ret, uint nextOffset) = asUint56(encoded, offset);
    return (bytes7(ret), nextOffset);
  }

  function asUint64Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint64 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 8)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint64(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint64 ret, uint nextOffset) {
    (ret, nextOffset) = asUint64Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes8Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes8, uint) {
    (uint64 ret, uint nextOffset) = asUint64Unchecked(encoded, offset);
    return (bytes8(ret), nextOffset);
  }

  function asBytes8(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes8, uint) {
    (uint64 ret, uint nextOffset) = asUint64(encoded, offset);
    return (bytes8(ret), nextOffset);
  }

  function asUint72Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint72 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 9)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint72(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint72 ret, uint nextOffset) {
    (ret, nextOffset) = asUint72Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes9Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes9, uint) {
    (uint72 ret, uint nextOffset) = asUint72Unchecked(encoded, offset);
    return (bytes9(ret), nextOffset);
  }

  function asBytes9(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes9, uint) {
    (uint72 ret, uint nextOffset) = asUint72(encoded, offset);
    return (bytes9(ret), nextOffset);
  }

  function asUint80Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint80 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 10)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint80(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint80 ret, uint nextOffset) {
    (ret, nextOffset) = asUint80Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes10Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes10, uint) {
    (uint80 ret, uint nextOffset) = asUint80Unchecked(encoded, offset);
    return (bytes10(ret), nextOffset);
  }

  function asBytes10(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes10, uint) {
    (uint80 ret, uint nextOffset) = asUint80(encoded, offset);
    return (bytes10(ret), nextOffset);
  }

  function asUint88Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint88 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 11)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint88(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint88 ret, uint nextOffset) {
    (ret, nextOffset) = asUint88Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes11Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes11, uint) {
    (uint88 ret, uint nextOffset) = asUint88Unchecked(encoded, offset);
    return (bytes11(ret), nextOffset);
  }

  function asBytes11(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes11, uint) {
    (uint88 ret, uint nextOffset) = asUint88(encoded, offset);
    return (bytes11(ret), nextOffset);
  }

  function asUint96Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint96 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 12)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint96(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint96 ret, uint nextOffset) {
    (ret, nextOffset) = asUint96Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes12Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes12, uint) {
    (uint96 ret, uint nextOffset) = asUint96Unchecked(encoded, offset);
    return (bytes12(ret), nextOffset);
  }

  function asBytes12(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes12, uint) {
    (uint96 ret, uint nextOffset) = asUint96(encoded, offset);
    return (bytes12(ret), nextOffset);
  }

  function asUint104Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint104 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 13)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint104(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint104 ret, uint nextOffset) {
    (ret, nextOffset) = asUint104Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes13Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes13, uint) {
    (uint104 ret, uint nextOffset) = asUint104Unchecked(encoded, offset);
    return (bytes13(ret), nextOffset);
  }

  function asBytes13(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes13, uint) {
    (uint104 ret, uint nextOffset) = asUint104(encoded, offset);
    return (bytes13(ret), nextOffset);
  }

  function asUint112Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint112 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 14)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint112(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint112 ret, uint nextOffset) {
    (ret, nextOffset) = asUint112Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes14Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes14, uint) {
    (uint112 ret, uint nextOffset) = asUint112Unchecked(encoded, offset);
    return (bytes14(ret), nextOffset);
  }

  function asBytes14(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes14, uint) {
    (uint112 ret, uint nextOffset) = asUint112(encoded, offset);
    return (bytes14(ret), nextOffset);
  }

  function asUint120Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint120 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 15)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint120(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint120 ret, uint nextOffset) {
    (ret, nextOffset) = asUint120Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes15Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes15, uint) {
    (uint120 ret, uint nextOffset) = asUint120Unchecked(encoded, offset);
    return (bytes15(ret), nextOffset);
  }

  function asBytes15(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes15, uint) {
    (uint120 ret, uint nextOffset) = asUint120(encoded, offset);
    return (bytes15(ret), nextOffset);
  }

  function asUint128Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint128 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 16)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint128(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint128 ret, uint nextOffset) {
    (ret, nextOffset) = asUint128Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes16Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes16, uint) {
    (uint128 ret, uint nextOffset) = asUint128Unchecked(encoded, offset);
    return (bytes16(ret), nextOffset);
  }

  function asBytes16(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes16, uint) {
    (uint128 ret, uint nextOffset) = asUint128(encoded, offset);
    return (bytes16(ret), nextOffset);
  }

  function asUint136Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint136 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 17)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint136(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint136 ret, uint nextOffset) {
    (ret, nextOffset) = asUint136Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes17Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes17, uint) {
    (uint136 ret, uint nextOffset) = asUint136Unchecked(encoded, offset);
    return (bytes17(ret), nextOffset);
  }

  function asBytes17(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes17, uint) {
    (uint136 ret, uint nextOffset) = asUint136(encoded, offset);
    return (bytes17(ret), nextOffset);
  }

  function asUint144Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint144 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 18)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint144(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint144 ret, uint nextOffset) {
    (ret, nextOffset) = asUint144Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes18Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes18, uint) {
    (uint144 ret, uint nextOffset) = asUint144Unchecked(encoded, offset);
    return (bytes18(ret), nextOffset);
  }

  function asBytes18(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes18, uint) {
    (uint144 ret, uint nextOffset) = asUint144(encoded, offset);
    return (bytes18(ret), nextOffset);
  }

  function asUint152Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint152 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 19)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint152(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint152 ret, uint nextOffset) {
    (ret, nextOffset) = asUint152Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes19Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes19, uint) {
    (uint152 ret, uint nextOffset) = asUint152Unchecked(encoded, offset);
    return (bytes19(ret), nextOffset);
  }

  function asBytes19(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes19, uint) {
    (uint152 ret, uint nextOffset) = asUint152(encoded, offset);
    return (bytes19(ret), nextOffset);
  }

  function asUint160Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint160 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 20)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint160(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint160 ret, uint nextOffset) {
    (ret, nextOffset) = asUint160Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes20Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes20, uint) {
    (uint160 ret, uint nextOffset) = asUint160Unchecked(encoded, offset);
    return (bytes20(ret), nextOffset);
  }

  function asBytes20(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes20, uint) {
    (uint160 ret, uint nextOffset) = asUint160(encoded, offset);
    return (bytes20(ret), nextOffset);
  }

  function asUint168Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint168 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 21)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint168(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint168 ret, uint nextOffset) {
    (ret, nextOffset) = asUint168Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes21Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes21, uint) {
    (uint168 ret, uint nextOffset) = asUint168Unchecked(encoded, offset);
    return (bytes21(ret), nextOffset);
  }

  function asBytes21(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes21, uint) {
    (uint168 ret, uint nextOffset) = asUint168(encoded, offset);
    return (bytes21(ret), nextOffset);
  }

  function asUint176Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint176 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 22)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint176(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint176 ret, uint nextOffset) {
    (ret, nextOffset) = asUint176Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes22Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes22, uint) {
    (uint176 ret, uint nextOffset) = asUint176Unchecked(encoded, offset);
    return (bytes22(ret), nextOffset);
  }

  function asBytes22(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes22, uint) {
    (uint176 ret, uint nextOffset) = asUint176(encoded, offset);
    return (bytes22(ret), nextOffset);
  }

  function asUint184Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint184 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 23)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint184(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint184 ret, uint nextOffset) {
    (ret, nextOffset) = asUint184Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes23Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes23, uint) {
    (uint184 ret, uint nextOffset) = asUint184Unchecked(encoded, offset);
    return (bytes23(ret), nextOffset);
  }

  function asBytes23(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes23, uint) {
    (uint184 ret, uint nextOffset) = asUint184(encoded, offset);
    return (bytes23(ret), nextOffset);
  }

  function asUint192Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint192 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 24)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint192(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint192 ret, uint nextOffset) {
    (ret, nextOffset) = asUint192Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes24Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes24, uint) {
    (uint192 ret, uint nextOffset) = asUint192Unchecked(encoded, offset);
    return (bytes24(ret), nextOffset);
  }

  function asBytes24(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes24, uint) {
    (uint192 ret, uint nextOffset) = asUint192(encoded, offset);
    return (bytes24(ret), nextOffset);
  }

  function asUint200Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint200 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 25)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint200(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint200 ret, uint nextOffset) {
    (ret, nextOffset) = asUint200Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes25Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes25, uint) {
    (uint200 ret, uint nextOffset) = asUint200Unchecked(encoded, offset);
    return (bytes25(ret), nextOffset);
  }

  function asBytes25(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes25, uint) {
    (uint200 ret, uint nextOffset) = asUint200(encoded, offset);
    return (bytes25(ret), nextOffset);
  }

  function asUint208Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint208 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 26)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint208(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint208 ret, uint nextOffset) {
    (ret, nextOffset) = asUint208Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes26Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes26, uint) {
    (uint208 ret, uint nextOffset) = asUint208Unchecked(encoded, offset);
    return (bytes26(ret), nextOffset);
  }

  function asBytes26(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes26, uint) {
    (uint208 ret, uint nextOffset) = asUint208(encoded, offset);
    return (bytes26(ret), nextOffset);
  }

  function asUint216Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint216 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 27)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint216(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint216 ret, uint nextOffset) {
    (ret, nextOffset) = asUint216Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes27Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes27, uint) {
    (uint216 ret, uint nextOffset) = asUint216Unchecked(encoded, offset);
    return (bytes27(ret), nextOffset);
  }

  function asBytes27(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes27, uint) {
    (uint216 ret, uint nextOffset) = asUint216(encoded, offset);
    return (bytes27(ret), nextOffset);
  }

  function asUint224Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint224 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 28)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint224(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint224 ret, uint nextOffset) {
    (ret, nextOffset) = asUint224Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes28Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes28, uint) {
    (uint224 ret, uint nextOffset) = asUint224Unchecked(encoded, offset);
    return (bytes28(ret), nextOffset);
  }

  function asBytes28(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes28, uint) {
    (uint224 ret, uint nextOffset) = asUint224(encoded, offset);
    return (bytes28(ret), nextOffset);
  }

  function asUint232Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint232 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 29)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint232(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint232 ret, uint nextOffset) {
    (ret, nextOffset) = asUint232Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes29Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes29, uint) {
    (uint232 ret, uint nextOffset) = asUint232Unchecked(encoded, offset);
    return (bytes29(ret), nextOffset);
  }

  function asBytes29(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes29, uint) {
    (uint232 ret, uint nextOffset) = asUint232(encoded, offset);
    return (bytes29(ret), nextOffset);
  }

  function asUint240Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint240 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 30)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint240(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint240 ret, uint nextOffset) {
    (ret, nextOffset) = asUint240Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes30Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes30, uint) {
    (uint240 ret, uint nextOffset) = asUint240Unchecked(encoded, offset);
    return (bytes30(ret), nextOffset);
  }

  function asBytes30(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes30, uint) {
    (uint240 ret, uint nextOffset) = asUint240(encoded, offset);
    return (bytes30(ret), nextOffset);
  }

  function asUint248Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint248 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 31)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint248(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint248 ret, uint nextOffset) {
    (ret, nextOffset) = asUint248Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes31Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes31, uint) {
    (uint248 ret, uint nextOffset) = asUint248Unchecked(encoded, offset);
    return (bytes31(ret), nextOffset);
  }

  function asBytes31(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes31, uint) {
    (uint248 ret, uint nextOffset) = asUint248(encoded, offset);
    return (bytes31(ret), nextOffset);
  }

  function asUint256Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint256 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 32)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint256(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint256 ret, uint nextOffset) {
    (ret, nextOffset) = asUint256Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes32Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes32, uint) {
    (uint256 ret, uint nextOffset) = asUint256Unchecked(encoded, offset);
    return (bytes32(ret), nextOffset);
  }

  function asBytes32(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes32, uint) {
    (uint256 ret, uint nextOffset) = asUint256(encoded, offset);
    return (bytes32(ret), nextOffset);
  }
}

// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.19;

type WeiPrice is uint256;

type GasPrice is uint256;

type Gas is uint256;

type Dollar is uint256;

type Wei is uint256;

type LocalNative is uint256;

type TargetNative is uint256;

using {
    addWei as +,
    subWei as -,
    lteWei as <=,
    ltWei as <,
    gtWei as >,
    eqWei as ==,
    neqWei as !=
} for Wei global;
using {addTargetNative as +, subTargetNative as -} for TargetNative global;
using {
    leLocalNative as <,
    leqLocalNative as <=,
    neqLocalNative as !=,
    addLocalNative as +,
    subLocalNative as -
} for LocalNative global;
using {
    ltGas as <,
    lteGas as <=,
    subGas as -
} for Gas global;

using WeiLib for Wei;
using GasLib for Gas;
using DollarLib for Dollar;
using WeiPriceLib for WeiPrice;
using GasPriceLib for GasPrice;

function ltWei(Wei a, Wei b) pure returns (bool) {
    return Wei.unwrap(a) < Wei.unwrap(b);
}

function eqWei(Wei a, Wei b) pure returns (bool) {
    return Wei.unwrap(a) == Wei.unwrap(b);
}

function gtWei(Wei a, Wei b) pure returns (bool) {
    return Wei.unwrap(a) > Wei.unwrap(b);
}

function lteWei(Wei a, Wei b) pure returns (bool) {
    return Wei.unwrap(a) <= Wei.unwrap(b);
}

function subWei(Wei a, Wei b) pure returns (Wei) {
    return Wei.wrap(Wei.unwrap(a) - Wei.unwrap(b));
}

function addWei(Wei a, Wei b) pure returns (Wei) {
    return Wei.wrap(Wei.unwrap(a) + Wei.unwrap(b));
}

function neqWei(Wei a, Wei b) pure returns (bool) {
    return Wei.unwrap(a) != Wei.unwrap(b);
}

function ltGas(Gas a, Gas b) pure returns (bool) {
    return Gas.unwrap(a) < Gas.unwrap(b);
}

function lteGas(Gas a, Gas b) pure returns (bool) {
    return Gas.unwrap(a) <= Gas.unwrap(b);
}

function subGas(Gas a, Gas b) pure returns (Gas) {
    return Gas.wrap(Gas.unwrap(a) - Gas.unwrap(b));
}

function addTargetNative(TargetNative a, TargetNative b) pure returns (TargetNative) {
    return TargetNative.wrap(TargetNative.unwrap(a) + TargetNative.unwrap(b));
}

function subTargetNative(TargetNative a, TargetNative b) pure returns (TargetNative) {
    return TargetNative.wrap(TargetNative.unwrap(a) - TargetNative.unwrap(b));
}

function addLocalNative(LocalNative a, LocalNative b) pure returns (LocalNative) {
    return LocalNative.wrap(LocalNative.unwrap(a) + LocalNative.unwrap(b));
}

function subLocalNative(LocalNative a, LocalNative b) pure returns (LocalNative) {
    return LocalNative.wrap(LocalNative.unwrap(a) - LocalNative.unwrap(b));
}

function neqLocalNative(LocalNative a, LocalNative b) pure returns (bool) {
    return LocalNative.unwrap(a) != LocalNative.unwrap(b);
}

function leLocalNative(LocalNative a, LocalNative b) pure returns (bool) {
    return LocalNative.unwrap(a) < LocalNative.unwrap(b);
}

function leqLocalNative(LocalNative a, LocalNative b) pure returns (bool) {
    return LocalNative.unwrap(a) <= LocalNative.unwrap(b);
}

library WeiLib {
    using {
        toDollars,
        toGas,
        convertAsset,
        min,
        max,
        scale,
        unwrap,
        asGasPrice,
        asTargetNative,
        asLocalNative
    } for Wei;

    function min(Wei x, Wei maxVal) internal pure returns (Wei) {
        return x > maxVal ? maxVal : x;
    }

    function max(Wei x, Wei maxVal) internal pure returns (Wei) {
        return x < maxVal ? maxVal : x;
    }

    function asTargetNative(Wei w) internal pure returns (TargetNative) {
        return TargetNative.wrap(Wei.unwrap(w));
    }

    function asLocalNative(Wei w) internal pure returns (LocalNative) {
        return LocalNative.wrap(Wei.unwrap(w));
    }

    function toDollars(Wei w, WeiPrice price) internal pure returns (Dollar) {
        return Dollar.wrap(Wei.unwrap(w) * WeiPrice.unwrap(price));
    }

    function toGas(Wei w, GasPrice price) internal pure returns (Gas) {
        return Gas.wrap(Wei.unwrap(w) / GasPrice.unwrap(price));
    }

    function scale(Wei w, Gas num, Gas denom) internal pure returns (Wei) {
        return Wei.wrap(Wei.unwrap(w) * Gas.unwrap(num) / Gas.unwrap(denom));
    }

    function unwrap(Wei w) internal pure returns (uint256) {
        return Wei.unwrap(w);
    }

    function asGasPrice(Wei w) internal pure returns (GasPrice) {
        return GasPrice.wrap(Wei.unwrap(w));
    }

    function convertAsset(
        Wei w,
        WeiPrice fromPrice,
        WeiPrice toPrice,
        uint32 multiplierNum,
        uint32 multiplierDenom,
        bool roundUp
    ) internal pure returns (Wei) {
        // console.log("heyo");
        Dollar numerator = w.toDollars(fromPrice).mul(multiplierNum);
        // console.log("numerator", numerator.unwrap());
        // console.log("multiplierDenom", multiplierDenom);
        // console.log("toPrice", toPrice.unwrap());
        WeiPrice denom = toPrice.mul(multiplierDenom);
        // console.log("denom", denom.unwrap());
        Wei res = numerator.toWei(denom, roundUp);
        // console.log("res", res.unwrap());
        return res;
    }
}

library GasLib {
    using {toWei, unwrap} for Gas;

    function min(Gas x, Gas maxVal) internal pure returns (Gas) {
        return x < maxVal ? x : maxVal;
    }

    function toWei(Gas w, GasPrice price) internal pure returns (Wei) {
        return Wei.wrap(w.unwrap() * price.unwrap());
    }

    function unwrap(Gas w) internal pure returns (uint256) {
        return Gas.unwrap(w);
    }
}

library DollarLib {
    using {toWei, mul, unwrap} for Dollar;

    function mul(Dollar a, uint256 b) internal pure returns (Dollar) {
        return Dollar.wrap(a.unwrap() * b);
    }

    function toWei(Dollar w, WeiPrice price, bool roundUp) internal pure returns (Wei) {
        return Wei.wrap((w.unwrap() + (roundUp ? price.unwrap() - 1 : 0)) / price.unwrap());
    }

    function toGas(Dollar w, GasPrice price, WeiPrice weiPrice) internal pure returns (Gas) {
        return w.toWei(weiPrice, false).toGas(price);
    }

    function unwrap(Dollar w) internal pure returns (uint256) {
        return Dollar.unwrap(w);
    }
}

library WeiPriceLib {
    using {mul, unwrap} for WeiPrice;

    function mul(WeiPrice a, uint256 b) internal pure returns (WeiPrice) {
        return WeiPrice.wrap(a.unwrap() * b);
    }

    function unwrap(WeiPrice w) internal pure returns (uint256) {
        return WeiPrice.unwrap(w);
    }
}

library GasPriceLib {
    using {unwrap, priceAsWei} for GasPrice;

    function priceAsWei(GasPrice w) internal pure returns (Wei) {
        return Wei.wrap(w.unwrap());
    }

    function unwrap(GasPrice w) internal pure returns (uint256) {
        return GasPrice.unwrap(w);
    }
}

library TargetNativeLib {
    using {unwrap, asNative} for TargetNative;

    function unwrap(TargetNative w) internal pure returns (uint256) {
        return TargetNative.unwrap(w);
    }

    function asNative(TargetNative w) internal pure returns (Wei) {
        return Wei.wrap(TargetNative.unwrap(w));
    }
}

library LocalNativeLib {
    using {unwrap, asNative} for LocalNative;

    function unwrap(LocalNative w) internal pure returns (uint256) {
        return LocalNative.unwrap(w);
    }

    function asNative(LocalNative w) internal pure returns (Wei) {
        return Wei.wrap(LocalNative.unwrap(w));
    }
}

// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "./TypedUnits.sol";

interface IDeliveryProvider {
    function quoteDeliveryPrice(
        uint16 targetChain,
        TargetNative receiverValue,
        bytes memory encodedExecutionParams
    ) external view returns (LocalNative nativePriceQuote, bytes memory encodedExecutionInfo);

    function quoteAssetConversion(
        uint16 targetChain,
        LocalNative currentChainAmount
    ) external view returns (TargetNative targetChainAmount);

    /**
     * @notice This function should return a payable address on this (source) chain where all awards
     *     should be sent for the relay provider.
     *
     */
    function getRewardAddress() external view returns (address payable rewardAddress);

    /**
     * @notice This function determines whether a relay provider supports deliveries to a given chain
     *     or not.
     *
     * @param targetChain - The chain which is being delivered to.
     */
    function isChainSupported(uint16 targetChain) external view returns (bool supported);

    /**
     * @notice If a DeliveryProvider supports a given chain, this function should provide the contract
     *      address (in wormhole format) of the relay provider on that chain.
     *
     * @param targetChain - The chain which is being delivered to.
     */
    function getTargetChainAddress(uint16 targetChain)
        external
        view
        returns (bytes32 deliveryProviderAddress);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./WormholeTypes.sol";

interface IBRNWormholeDeliveryProviderEventsErrors {
    error CallerMustBeWormholeRelayer();
    error WormholeVAAVerificationFailed(string reason);
    error WormholeReceiptVAAEmitterMismatch(bytes32 expected, bytes32 actual);
    error WormholeDeliveryVAASourceChainMismatch(WormholeChainId expected, WormholeChainId actual);
    error WormholeReceiptVAAEmitterChainMismatch(WormholeChainId expected, WormholeChainId actual);
    error WormholeRedeliveryVAAEmitterChainMismatch(WormholeChainId expected, WormholeChainId actual);
    error WormholeRedeliveryVAAEmitterMismatch(bytes32 expected, bytes32 actual);
    error WormholeRedeliveryVAAKeyMismatch(VaaKey expected, VaaKey actual);
    error WormholeRedeliveryVAATargetChainMismatch(WormholeChainId expected, WormholeChainId actual);
    error NotAuthorized();
    error NoFunds();
    error NativeTransferFailed();
    error ParamterLengthMismatch();

    event FundsDepositedForRelaying(uint256 indexed deliveryVAASequenceNumber, uint256 indexed amount);
    event DeliveryFeeClaimed(
        uint256 indexed deliveryVAASequenceNumber, RelayerAddress indexed relayer, uint256 indexed amount
    );
    event RedeliveryFeeClaimed(
        uint256 indexed redeliveryVAASequenceNumber, RelayerAddress indexed relayer, uint256 indexed amount
    );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "wormhole-contracts/interfaces/relayer/TypedUnits.sol";
import {IWormholeRelayer, VaaKey} from "wormhole-contracts/interfaces/relayer/IWormholeRelayerTyped.sol";

import "ta-common/TATypes.sol";

struct ReceiptVAAPayload {
    RelayerAddress relayerAddress;
    VaaKey deliveryVAAKey;
}

type WormholeChainId is uint16;

function wormholeChainIdEquality(WormholeChainId a, WormholeChainId b) pure returns (bool) {
    return WormholeChainId.unwrap(a) == WormholeChainId.unwrap(b);
}

function wormholeChainIdInequality(WormholeChainId a, WormholeChainId b) pure returns (bool) {
    return WormholeChainId.unwrap(a) != WormholeChainId.unwrap(b);
}

using {wormholeChainIdInequality as !=, wormholeChainIdEquality as ==} for WormholeChainId global;

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

//////////////////////////// UDVTS ////////////////////////////

type RelayerAddress is address;

function relayerEquality(RelayerAddress a, RelayerAddress b) pure returns (bool) {
    return RelayerAddress.unwrap(a) == RelayerAddress.unwrap(b);
}

function relayerInequality(RelayerAddress a, RelayerAddress b) pure returns (bool) {
    return RelayerAddress.unwrap(a) != RelayerAddress.unwrap(b);
}

using {relayerEquality as ==, relayerInequality as !=} for RelayerAddress global;

type DelegatorAddress is address;

function delegatorEquality(DelegatorAddress a, DelegatorAddress b) pure returns (bool) {
    return DelegatorAddress.unwrap(a) == DelegatorAddress.unwrap(b);
}

function delegatorInequality(DelegatorAddress a, DelegatorAddress b) pure returns (bool) {
    return DelegatorAddress.unwrap(a) != DelegatorAddress.unwrap(b);
}

using {delegatorEquality as ==, delegatorInequality as !=} for DelegatorAddress global;

type RelayerAccountAddress is address;

function relayerAccountEquality(RelayerAccountAddress a, RelayerAccountAddress b) pure returns (bool) {
    return RelayerAccountAddress.unwrap(a) == RelayerAccountAddress.unwrap(b);
}

function relayerAccountInequality(RelayerAccountAddress a, RelayerAccountAddress b) pure returns (bool) {
    return RelayerAccountAddress.unwrap(a) != RelayerAccountAddress.unwrap(b);
}

using {relayerAccountEquality as ==, relayerAccountInequality as !=} for RelayerAccountAddress global;

type TokenAddress is address;

function tokenEquality(TokenAddress a, TokenAddress b) pure returns (bool) {
    return TokenAddress.unwrap(a) == TokenAddress.unwrap(b);
}

function tokenInequality(TokenAddress a, TokenAddress b) pure returns (bool) {
    return TokenAddress.unwrap(a) != TokenAddress.unwrap(b);
}

using {tokenEquality as ==, tokenInequality as !=} for TokenAddress global;

//////////////////////////// Structs ////////////////////////////

struct RelayerState {
    uint16[] cdf;
    RelayerAddress[] relayers;
}

//////////////////////////// Enums ////////////////////////////

enum RelayerStatus {
    Uninitialized,
    Active,
    Exiting,
    Jailed
}