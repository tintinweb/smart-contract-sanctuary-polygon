// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "evm-gateway-contract/contracts/IGateway.sol";
import "evm-gateway-contract/contracts/Utils.sol";

/// @title CrossTalkUtils
/// @author Router Protocol
/// @notice This contract can be used to abstract the complexities while using the
/// Router CrossTalk framework.
library CrossTalkUtils {
  /// @notice Fuction to get whether the calls were executed on the destination chain.
  /// @param execFlags Array of boolean flags which indicate the execution status of calls on dest chain.
  /// @return boolean value indicating whether the calls were successfully executed on destination chain.
  function getTxStatusForAtomicCall(
    bool[] calldata execFlags
  ) internal pure returns (bool) {
    return execFlags[execFlags.length - 1] == true;
  }

  /// @notice Fuction to get the index of call out of an array of calls that failed on the destination chain.
  /// @param execFlags Array of boolean flags which indicate the execution status of calls on dest chain.
  /// @return index of call that failed
  function getTheIndexOfCallFailure(
    bool[] calldata execFlags
  ) internal pure returns (uint8) {
    require(getTxStatusForAtomicCall(execFlags), "No calls failed");

    for (uint8 i = 0; i < execFlags.length; i++) {
      if (execFlags[i] == false) {
        return i;
      }
    }

    return 0;
  }

  /// @notice Function to convert address to bytes
  /// @param addr address to be converted
  /// @return b bytes pertaining to address addr
  function toBytes(address addr) internal pure returns (bytes memory b) {
    assembly {
      let m := mload(0x40)
      addr := and(addr, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      mstore(
        add(m, 20),
        xor(0x140000000000000000000000000000000000000000, addr)
      )
      mstore(0x40, add(m, 52))
      b := m
    }
  }

  /// @notice Function to convert bytes to address
  /// @param _bytes bytes to be converted
  /// @return addr address pertaining to the bytes
  function toAddress(bytes memory _bytes) internal pure returns (address addr) {
    bytes20 srcTokenAddress;
    assembly {
      srcTokenAddress := mload(add(_bytes, 0x20))
    }
    addr = address(srcTokenAddress);
  }

  /// @notice Function to send a single request without acknowledgement to the destination chain.
  /// @dev You will be able to send a single request to a single contract on the destination chain and
  /// you don't need the acknowledgement back on the source chain.
  /// @param gatewayContract address of the gateway contract.
  /// @param expiryTimestamp timestamp when the call expires. If this time passes by, the call will fail
  /// on the destination chain. If you don't want to add an expiry timestamp, set it to zero.
  /// @param destChainParams dest chain params include the destChainType, destChainId, the gas limit
  /// required to execute handler function on the destination chain and the gas price of destination chain.
  /// @param destinationContractAddress Contract address (in bytes format) of the contract which will be
  /// called on the destination chain which will handle the payload.
  /// @param payload abi encoded data that you want to send to the destination chain.
  /// @return Returns the nonce from the gateway contract.
  function singleRequestWithoutAcknowledgement(
    address gatewayContract,
    uint64 expiryTimestamp,
    Utils.DestinationChainParams memory destChainParams,
    bytes memory destinationContractAddress,
    bytes memory payload
  ) internal returns (uint64) {
    if (expiryTimestamp == 0) {
      expiryTimestamp = type(uint64).max;
    }

    bytes[] memory addresses = new bytes[](1);
    addresses[0] = destinationContractAddress;
    bytes[] memory payloads = new bytes[](1);
    payloads[0] = payload;

    return
      IGateway(gatewayContract).requestToDest(
        expiryTimestamp,
        false,
        Utils.AckType.NO_ACK,
        Utils.AckGasParams(0, 0),
        destChainParams,
        Utils.ContractCalls(payloads, addresses)
      );
  }

  /// @notice Function to send a single request with acknowledgement to the destination chain.
  /// @dev You will be able to send a single request to a single contract on the destination chain and
  /// you need the acknowledgement back on the source chain.
  /// @param gatewayContract address of the gateway contract.
  /// @param expiryTimestamp timestamp when the call expires. If this time passes by, the call will fail
  /// on the destination chain. If you don't want to add an expiry timestamp, set it to zero.
  /// @param ackType type of acknowledgement you want: ACK_ON_SUCCESS, ACK_ON_ERR, ACK_ON_BOTH.
  /// @param ackGasParams This includes the gas limit required for the execution of handler function for
  /// crosstalk acknowledgement on the source chain and the gas price of the source chain.
  /// @param destChainParams dest chain params include the destChainType, destChainId, the gas limit
  /// required to execute handler function on the destination chain and the gas price of destination chain.
  /// @param destinationContractAddress Contract address (in bytes format) of the contract which will be
  /// called on the destination chain which will handle the payload.
  /// @param payload abi encoded data that you want to send to the destination chain.
  /// @return Returns the nonce from the gateway contract.
  function singleRequestWithAcknowledgement(
    address gatewayContract,
    uint64 expiryTimestamp,
    Utils.AckType ackType,
    Utils.AckGasParams memory ackGasParams,
    Utils.DestinationChainParams memory destChainParams,
    bytes memory destinationContractAddress,
    bytes memory payload
  ) internal returns (uint64) {
    if (expiryTimestamp == 0) {
      expiryTimestamp = type(uint64).max;
    }

    bytes[] memory addresses = new bytes[](1);
    addresses[0] = destinationContractAddress;
    bytes[] memory payloads = new bytes[](1);
    payloads[0] = payload;

    return
      IGateway(gatewayContract).requestToDest(
        expiryTimestamp,
        false,
        ackType,
        ackGasParams,
        destChainParams,
        Utils.ContractCalls(payloads, addresses)
      );
  }

  /// @notice Function to send multiple requests without acknowledgement to multiple contracts on the
  /// destination chain.
  /// @dev You will be able to send multiple requests to multiple contracts on the destination chain and
  /// you don't need the acknowledgement back on the source chain.
  /// @param gatewayContract address of the gateway contract.
  /// @param expiryTimestamp timestamp when the call expires. If this time passes by, the call will fail
  /// on the destination chain. If you don't want to add an expiry timestamp, set it to zero.
  /// @param isAtomicCalls boolean value suggesting whether the calls are atomic. If true, either all the
  /// calls will be executed or none will be executed on the destination chain. If false, even if some calls
  /// fail, others will not be affected.
  /// @param destChainParams dest chain params include the destChainType, destChainId, the gas limit
  /// required to execute handler function on the destination chain and the gas price of destination chain.
  /// @param destinationContractAddresses Array of contract addresses (in bytes format) of the contracts
  /// which will be called on the destination chain which will handle the respective payloads.
  /// @param payloads Array of abi encoded data that you want to send to the destination chain.
  /// @return Returns the nonce from the gateway contract.
  function multipleRequestsWithoutAcknowledgement(
    address gatewayContract,
    uint64 expiryTimestamp,
    bool isAtomicCalls,
    Utils.DestinationChainParams memory destChainParams,
    bytes[] memory destinationContractAddresses,
    bytes[] memory payloads
  ) internal returns (uint64) {
    if (expiryTimestamp == 0) {
      expiryTimestamp = type(uint64).max;
    }

    return
      IGateway(gatewayContract).requestToDest(
        expiryTimestamp,
        isAtomicCalls,
        Utils.AckType.NO_ACK,
        Utils.AckGasParams(0, 0),
        destChainParams,
        Utils.ContractCalls(payloads, destinationContractAddresses)
      );
  }

  /// @notice Function to send multiple requests with acknowledgement to multiple contracts on the
  /// destination chain.
  /// @dev You will be able to send multiple requests to multiple contracts on the destination chain and
  /// you need the acknowledgement back on the source chain.
  /// @param gatewayContract address of the gateway contract.
  /// @param expiryTimestamp timestamp when the call expires. If this time passes by, the call will fail
  /// on the destination chain. If you don't want to add an expiry timestamp, set it to zero.
  /// @param isAtomicCalls boolean value suggesting whether the calls are atomic. If true, either all the
  /// calls will be executed or none will be executed on the destination chain. If false, even if some calls
  /// fail, others will not be affected.
  /// @param ackType type of acknowledgement you want: ACK_ON_SUCCESS, ACK_ON_ERR, ACK_ON_BOTH.
  /// @param ackGasParams This includes the gas limit required for the execution of handler function for
  /// crosstalk acknowledgement on the source chain and the gas price of the source chain.
  /// @param destChainParams dest chain params include the destChainType, destChainId, the gas limit
  /// required to execute handler function on the destination chain and the gas price of destination chain.
  /// @param destinationContractAddresses Array of contract addresses (in bytes format) of the contracts
  /// which will be called on the destination chain which will handle the respective payloads.
  /// @param payloads Array of abi encoded data that you want to send to the destination chain.
  /// @return Returns the nonce from the gateway contract.
  function multipleRequestsWithAcknowledgement(
    address gatewayContract,
    uint64 expiryTimestamp,
    bool isAtomicCalls,
    Utils.AckType ackType,
    Utils.AckGasParams memory ackGasParams,
    Utils.DestinationChainParams memory destChainParams,
    bytes[] memory destinationContractAddresses,
    bytes[] memory payloads
  ) internal returns (uint64) {
    if (expiryTimestamp == 0) {
      expiryTimestamp = type(uint64).max;
    }

    return
      IGateway(gatewayContract).requestToDest(
        expiryTimestamp,
        isAtomicCalls,
        ackType,
        ackGasParams,
        destChainParams,
        Utils.ContractCalls(payloads, destinationContractAddresses)
      );
  }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.0 <0.9.0;

import "evm-gateway-contract/contracts/ICrossTalkApplication.sol";
import "evm-gateway-contract/contracts/Utils.sol";
import "./CrossTalkUtils.sol";

contract PingPong is ICrossTalkApplication {
  address public gatewayContract;
  string public greeting;
  uint64 public lastEventIdentifier;
  uint64 public destGasLimit;
  uint64 public ackGasLimit;

  error CustomError(string message);
  event ExecutionStatus(uint64 eventIdentifier, bool isSuccess);
  event ReceivedSrcChainIdAndType(uint64 chainType, string chainID);

  constructor(
    address payable gatewayAddress,
    uint64 _destGasLimit,
    uint64 _ackGasLimit
  ) {
    gatewayContract = gatewayAddress;
    destGasLimit = _destGasLimit;
    ackGasLimit = _ackGasLimit;
  }

  function pingDestination(
    uint64 chainType,
    string memory chainId,
    uint64 destGasPrice,
    uint64 ackGasPrice,
    bytes memory destinationContractAddress,
    string memory str,
    uint64 expiryDurationInSeconds
  ) public payable {
    bytes memory payload = abi.encode(str);
    uint64 expiryTimestamp = uint64(block.timestamp) + expiryDurationInSeconds;
    Utils.DestinationChainParams memory destChainParams = Utils
      .DestinationChainParams(destGasLimit, destGasPrice, chainType, chainId);

    Utils.AckType ackType = Utils.AckType.ACK_ON_SUCCESS;
    Utils.AckGasParams memory ackGasParams = Utils.AckGasParams(
      ackGasLimit,
      ackGasPrice
    );

    lastEventIdentifier = CrossTalkUtils.singleRequestWithAcknowledgement(
      address(gatewayContract),
      expiryTimestamp,
      ackType,
      ackGasParams,
      destChainParams,
      destinationContractAddress,
      payload
    );
  }

  function handleRequestFromSource(
    bytes memory, //srcContractAddress
    bytes memory payload,
    string memory srcChainId,
    uint64 srcChainType
  ) external override returns (bytes memory) {
    require(msg.sender == gatewayContract);

    string memory sampleStr = abi.decode(payload, (string));

    if (
      keccak256(abi.encodePacked(sampleStr)) == keccak256(abi.encodePacked(""))
    ) {
      revert CustomError("String should not be empty");
    }
    greeting = sampleStr;
    return abi.encode(srcChainId, srcChainType);
  }

  function handleCrossTalkAck(
    uint64 eventIdentifier,
    bool[] memory execFlags,
    bytes[] memory execData
  ) external override {
    require(lastEventIdentifier == eventIdentifier);
    bytes memory _execData = abi.decode(execData[0], (bytes));

    (string memory chainID, uint64 chainType) = abi.decode(
      _execData,
      (string, uint64)
    );

    // emits the event identifier and true as execFlags[0]
    emit ExecutionStatus(eventIdentifier, execFlags[0]);
    // emits the source chain Id and type that it gets back from the dest chain
    emit ReceivedSrcChainIdAndType(chainType, chainID);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @dev CrossTalk flow Interface.
 */
interface ICrossTalkApplication {
    function handleRequestFromSource(
        bytes memory srcContractAddress,
        bytes memory payload,
        string memory srcChainId,
        uint64 srcChainType
    ) external returns (bytes memory);

    function handleCrossTalkAck(uint64 eventIdentifier, bool[] memory execFlags, bytes[] memory execData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Utils.sol";

/**
 * @dev Interface of the Gateway Self External Calls.
 */
interface IGateway {
    function requestToRouter(bytes memory payload, string memory routerBridgeContract) external;

    function executeHandlerCalls(
        string memory sender,
        bytes[] memory handlers,
        bytes[] memory payloads,
        bool isAtomic
    ) external returns (bool[] memory);

    function requestToDest(
        uint64 expTimestamp,
        bool isAtomicCalls,
        Utils.AckType ackType,
        Utils.AckGasParams memory ackGasParams,
        Utils.DestinationChainParams memory destChainParams,
        Utils.ContractCalls memory contractCalls
    ) external returns (uint64);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library Utils {
    // This is used purely to avoid stack too deep errors
    // represents everything about a given validator set
    struct ValsetArgs {
        // the validators in this set, represented by an Ethereum address
        address[] validators;
        // the powers of the given validators in the same order as above
        uint64[] powers;
        // the nonce of this validator set
        uint64 valsetNonce;
    }

    // This is being used purely to avoid stack too deep errors
    struct RouterRequestPayload {
        // the sender address
        string routerBridgeAddress;
        string relayerRouterAddress;
        uint256 relayerFee;
        uint256 outgoingTxFee;
        bool isAtomic;
        uint64 expTimestamp;
        // The user contract address
        bytes[] handlers;
        bytes[] payloads;
        uint64 outboundTxNonce;
    }

    struct AckGasParams {
        uint64 gasLimit;
        uint64 gasPrice;
    }

    struct SourceChainParams {
        uint64 crossTalkNonce;
        uint64 expTimestamp;
        bool isAtomicCalls;
        uint64 chainType;
        string chainId;
    }
    struct SourceParams {
        bytes caller;
        uint64 chainType;
        string chainId;
    }

    struct DestinationChainParams {
        uint64 gasLimit;
        uint64 gasPrice;
        uint64 destChainType;
        string destChainId;
    }

    struct ContractCalls {
        bytes[] payloads;
        bytes[] destContractAddresses;
    }

    struct CrossTalkPayload {
        string relayerRouterAddress;
        bool isAtomic;
        uint64 eventIdentifier;
        uint64 expTimestamp;
        uint64 crossTalkNonce;
        SourceParams sourceParams;
        ContractCalls contractCalls;
    }

    struct CrossTalkAckPayload {
        uint64 crossTalkNonce;
        uint64 eventIdentifier;
        uint64 destChainType;
        string destChainId;
        bytes srcContractAddress;
        bool[] execFlags;
        bytes[] execData;
    }

    // This represents a validator signature
    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    enum AckType {
        NO_ACK,
        ACK_ON_SUCCESS,
        ACK_ON_ERROR,
        ACK_ON_BOTH
    }

    error IncorrectCheckpoint();
    error InvalidValsetNonce(uint64 newNonce, uint64 currentNonce);
    error MalformedNewValidatorSet();
    error MalformedCurrentValidatorSet();
    error InsufficientPower(uint64 cumulativePower, uint64 powerThreshold);
    error InvalidSignature();
    // constants
    string constant MSG_PREFIX = "\x19Ethereum Signed Message:\n32";
    // The number of 'votes' required to execute a valset
    // update or batch execution, set to 2/3 of 2^32
    uint64 constant constantPowerThreshold = 2863311530;
}