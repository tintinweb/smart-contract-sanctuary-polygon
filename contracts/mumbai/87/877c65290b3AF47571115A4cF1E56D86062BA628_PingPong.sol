//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "evm-gateway-contract/contracts/IGateway.sol";
import "evm-gateway-contract/contracts/ICrossTalkApplication.sol";
import "evm-gateway-contract/contracts/Utils.sol";

contract PingPong is ICrossTalkApplication {
  IGateway public gatewayContract;
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
    gatewayContract = IGateway(gatewayAddress);
    destGasLimit = _destGasLimit;
    ackGasLimit = _ackGasLimit;
  }

  function pingDestination(
    uint64 chainType,
    string memory chainId,
    uint64 destGasPrice,
    uint64 ackGasPrice,
    address destinationContractAddress,
    string memory str,
    uint64 expiryDurationInSeconds
  ) public payable {
    bytes memory payload = abi.encode(str);
    uint64 expiryTimestamp = uint64(block.timestamp) + expiryDurationInSeconds;
    bytes[] memory addresses = new bytes[](1);
    addresses[0] = toBytes(destinationContractAddress);
    bytes[] memory payloads = new bytes[](1);
    payloads[0] = payload;
    _pingDestination(
      expiryTimestamp,
      destGasPrice,
      ackGasPrice,
      chainType,
      chainId,
      payloads,
      addresses
    );
  }

  function _pingDestination(
    uint64 expiryTimestamp,
    uint64 destGasPrice,
    uint64 ackGasPrice,
    uint64 chainType,
    string memory chainId,
    bytes[] memory payloads,
    bytes[] memory addresses
  ) internal {
    lastEventIdentifier = gatewayContract.requestToDest(
      expiryTimestamp,
      false,
      Utils.AckType.ACK_ON_SUCCESS,
      Utils.AckGasParams(ackGasLimit, ackGasPrice),
      Utils.DestinationChainParams(
        destGasLimit,
        destGasPrice,
        chainType,
        chainId
      ),
      Utils.ContractCalls(payloads, addresses)
    );
  }

  function handleRequestFromSource(
    bytes memory, //srcContractAddress
    bytes memory payload,
    string memory srcChainId,
    uint64 srcChainType
  ) external override returns (bytes memory) {
    require(msg.sender == address(gatewayContract));

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
    require(lastEventIdentifier == eventIdentifier, "wrong event identifier");

    (uint64 chainType, string memory chainID) = abi.decode(
      execData[0],
      (uint64, string)
    );
    emit ExecutionStatus(eventIdentifier, execFlags[0]);
    emit ReceivedSrcChainIdAndType(chainType, chainID);
  }

  function toBytes(address a) public pure returns (bytes memory b) {
    assembly {
      let m := mload(0x40)
      a := and(a, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      mstore(add(m, 20), xor(0x140000000000000000000000000000000000000000, a))
      mstore(0x40, add(m, 52))
      b := m
    }
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