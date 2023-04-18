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
    function requestToRouter(
        uint256 routeAmount,
        string memory routeRecipient,
        bytes memory payload,
        string memory routerBridgeContract,
        uint256 gasLimit,
        bytes memory asmAddress
    ) external payable returns (uint64);

    function setDappMetadata(string memory feePayerAddress) external payable returns (uint64);

    function executeHandlerCalls(
        string memory sender,
        bytes[] memory handlers,
        bytes[] memory payloads,
        bool isAtomic
    ) external returns (bool[] memory, bytes[] memory);

    function requestToDest(
        Utils.RequestArgs memory requestArgs,
        Utils.AckType ackType,
        Utils.AckGasParams memory ackGasParams,
        Utils.DestinationChainParams memory destChainParams,
        Utils.ContractCalls memory contractCalls
    ) external payable returns (uint64);

    function readQueryToDest(
        Utils.RequestArgs memory requestArgs,
        Utils.AckGasParams memory ackGasParams,
        Utils.DestinationChainParams memory destChainParams,
        Utils.ContractCalls memory contractCalls
    ) external payable returns (uint64);

    function requestToRouterDefaultFee() external view returns (uint256 fees);

    function requestToDestDefaultFee() external view returns (uint256 fees);
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
        //route
        uint256 routeAmount;
        bytes routeRecipient;
        // the sender address
        string routerBridgeAddress;
        string relayerRouterAddress;
        bool isAtomic;
        uint64 chainTimestamp;
        uint64 expTimestamp;
        // The user contract address
        bytes asmAddress;
        bytes[] handlers;
        bytes[] payloads;
        uint64 outboundTxNonce;
    }

    struct AckGasParams {
        uint64 gasLimit;
        uint64 gasPrice;
    }

    struct InboundSourceInfo {
        uint256 routeAmount;
        string routeRecipient;
        uint64 eventNonce;
        uint64 srcChainType;
        string srcChainId;
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
        bytes asmAddress;
    }

    struct RequestArgs {
        uint64 expTimestamp;
        bool isAtomicCalls;
    }

    struct ContractCalls {
        bytes[] payloads;
        bytes[] destContractAddresses;
    }

    struct CrossTalkPayload {
        string relayerRouterAddress;
        bool isAtomic;
        uint64 eventIdentifier;
        uint64 chainTimestamp;
        uint64 expTimestamp;
        uint64 crossTalkNonce;
        bytes asmAddress;
        SourceParams sourceParams;
        ContractCalls contractCalls;
        bool isReadCall;
    }

    struct CrossTalkAckPayload {
        string relayerRouterAddress;
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
    uint64 constant constantPowerThreshold = 2791728742;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@routerprotocol/evm-gateway-contracts/contracts/IGateway.sol";
import "@routerprotocol/evm-gateway-contracts/contracts/Utils.sol";

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
    function toAddress(
        bytes memory _bytes
    ) internal pure returns (address addr) {
        bytes20 srcTokenAddress;
        assembly {
            srcTokenAddress := mload(add(_bytes, 0x20))
        }
        addr = address(srcTokenAddress);
    }

    /// @notice Function to get the crosstalk fees in native tokens of the source chain.
    /// @param  gatewayContract address of the gateway contract.
    /// @return fees required for the transaction in native tokens of source chain.
    function getCrossTalkFees(
        address gatewayContract
    ) internal view returns (uint256) {
        return IGateway(gatewayContract).requestToDestDefaultFee();
    }

    /// @notice Function to send a single request without acknowledgement to the destination chain.
    /// @dev You will be able to send a single request to a single contract on the destination chain and
    /// you don't need the acknowledgement back on the source chain.
    /// @param gatewayContract address of the gateway contract.
    /// @param requestArgs requestArgs consists of expiryTimestamp, isAtomicCalls boolean and feePayerEnum.
    /// expiryTimestamp: timestamp when the call expires. If this time passes by, the call will fail
    /// on the destination chain. If you don't want to add an expiry timestamp, set it to zero.
    /// isAtomicCalls: boolean value suggesting whether the calls are atomic. If true, either all the
    /// calls will be executed or none will be executed on the destination chain. If false, even if some calls
    /// fail, others will not be affected. In this case, true or false doesn't matter.
    /// feePayerEnum: fee payer enum can be either Utils.FeePayer.{APP, USER, NONE}. NONE can be used
    /// in case of meta tx. In case you use APP or USER, fee is deducted on router chain from the router address
    /// of the app or the user respectively.
    /// @param destChainParams dest chain params include the destChainType, destChainId, the gas limit
    /// required to execute handler function on the destination chain and the gas price of destination chain.
    /// @param destinationContractAddress Contract address (in bytes format) of the contract which will be
    /// called on the destination chain which will handle the payload.
    /// @param payload abi encoded data that you want to send to the destination chain.
    /// @return Returns the nonce from the gateway contract.
    function singleRequestWithoutAcknowledgement(
        address gatewayContract,
        Utils.RequestArgs memory requestArgs,
        Utils.DestinationChainParams memory destChainParams,
        bytes memory destinationContractAddress,
        bytes memory payload
    ) internal returns (uint64) {
        if (requestArgs.expTimestamp == 0) {
            requestArgs.expTimestamp = type(uint64).max;
        }

        bytes[] memory addresses = new bytes[](1);
        addresses[0] = destinationContractAddress;
        bytes[] memory payloads = new bytes[](1);
        payloads[0] = payload;

        return
            IGateway(gatewayContract).requestToDest{value: msg.value}(
                requestArgs,
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
    /// @param requestArgs requestArgs consists of expiryTimestamp, isAtomicCalls boolean and feePayerEnum.
    /// expiryTimestamp: timestamp when the call expires. If this time passes by, the call will fail
    /// on the destination chain. If you don't want to add an expiry timestamp, set it to zero.
    /// isAtomicCalls: boolean value suggesting whether the calls are atomic. If true, either all the
    /// calls will be executed or none will be executed on the destination chain. If false, even if some calls
    /// fail, others will not be affected. In this case, true or false doesn't matter.
    /// feePayerEnum: fee payer enum can be either Utils.FeePayer.{APP, USER, NONE}. NONE can be used
    /// in case of meta tx. In case you use APP or USER, fee is deducted on router chain from the router address
    /// of the app or the user respectively.
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
        Utils.RequestArgs memory requestArgs,
        Utils.AckType ackType,
        Utils.AckGasParams memory ackGasParams,
        Utils.DestinationChainParams memory destChainParams,
        bytes memory destinationContractAddress,
        bytes memory payload
    ) internal returns (uint64) {
        if (requestArgs.expTimestamp == 0) {
            requestArgs.expTimestamp = type(uint64).max;
        }

        bytes[] memory addresses = new bytes[](1);
        addresses[0] = destinationContractAddress;
        bytes[] memory payloads = new bytes[](1);
        payloads[0] = payload;

        return
            IGateway(gatewayContract).requestToDest{value: msg.value}(
                requestArgs,
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
    /// @param requestArgs requestArgs consists of expiryTimestamp, isAtomicCalls boolean and feePayerEnum.
    /// expiryTimestamp: timestamp when the call expires. If this time passes by, the call will fail
    /// on the destination chain. If you don't want to add an expiry timestamp, set it to zero.
    /// isAtomicCalls: boolean value suggesting whether the calls are atomic. If true, either all the
    /// calls will be executed or none will be executed on the destination chain. If false, even if some calls
    /// fail, others will not be affected.
    /// feePayerEnum: fee payer enum can be either Utils.FeePayer.{APP, USER, NONE}. NONE can be used
    /// in case of meta tx. In case you use APP or USER, fee is deducted on router chain from the router address
    /// of the app or the user respectively.
    /// @param destChainParams dest chain params include the destChainType, destChainId, the gas limit
    /// required to execute handler function on the destination chain and the gas price of destination chain.
    /// @param destinationContractAddresses Array of contract addresses (in bytes format) of the contracts
    /// which will be called on the destination chain which will handle the respective payloads.
    /// @param payloads Array of abi encoded data that you want to send to the destination chain.
    /// @return Returns the nonce from the gateway contract.
    function multipleRequestsWithoutAcknowledgement(
        address gatewayContract,
        Utils.RequestArgs memory requestArgs,
        Utils.DestinationChainParams memory destChainParams,
        bytes[] memory destinationContractAddresses,
        bytes[] memory payloads
    ) internal returns (uint64) {
        if (requestArgs.expTimestamp == 0) {
            requestArgs.expTimestamp = type(uint64).max;
        }

        return
            IGateway(gatewayContract).requestToDest{value: msg.value}(
                requestArgs,
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
    /// @param requestArgs requestArgs consists of expiryTimestamp, isAtomicCalls boolean and feePayerEnum.
    /// expiryTimestamp: timestamp when the call expires. If this time passes by, the call will fail
    /// on the destination chain. If you don't want to add an expiry timestamp, set it to zero.
    /// isAtomicCalls: boolean value suggesting whether the calls are atomic. If true, either all the
    /// calls will be executed or none will be executed on the destination chain. If false, even if some calls
    /// fail, others will not be affected.
    /// feePayerEnum: fee payer enum can be either Utils.FeePayer.{APP, USER, NONE}. NONE can be used
    /// in case of meta tx. In case you use APP or USER, fee is deducted on router chain from the router address
    /// of the app or the user respectively.
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
        Utils.RequestArgs memory requestArgs,
        Utils.AckType ackType,
        Utils.AckGasParams memory ackGasParams,
        Utils.DestinationChainParams memory destChainParams,
        bytes[] memory destinationContractAddresses,
        bytes[] memory payloads
    ) internal returns (uint64) {
        if (requestArgs.expTimestamp == 0) {
            requestArgs.expTimestamp = type(uint64).max;
        }

        return
            IGateway(gatewayContract).requestToDest{value: msg.value}(
                requestArgs,
                ackType,
                ackGasParams,
                destChainParams,
                Utils.ContractCalls(payloads, destinationContractAddresses)
            );
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "@routerprotocol/router-crosstalk-utils/contracts/CrossTalkUtils.sol";
import "@routerprotocol/evm-gateway-contracts/contracts/ICrossTalkApplication.sol";

/// @title PingPong
/// @author Shivam Agrawal
/// @notice This is a cross-chain ping pong smart contract to demonstrate how one can
/// utilise Router CrossTalk for cross-chain transactions.
contract PingPong is ICrossTalkApplication {
    address public owner;
    uint64 public currentRequestId;

    // srcChainType + srcChainId + requestId => pingFromSource
    mapping(uint64 => mapping(string => mapping(uint64 => string)))
        public pingFromSource;
    // requestId => ackMessage
    mapping(uint64 => string) public ackFromDestination;

    // instance of the Router's gateway contract
    IGateway public gatewayContract;

    // gas limit required to handle the cross-chain request on the destination chain.
    uint64 public destGasLimit;

    // gas limit required to handle the acknowledgement received on the source
    // chain back from the destination chain.
    uint64 public ackGasLimit;

    // custom error so that we can emit a custom error message
    error CustomError(string message);

    // event we will emit while sending a ping to destination chain
    event PingFromSource(
        uint64 indexed srcChainType,
        string indexed srcChainId,
        uint64 indexed requestId,
        string message
    );
    event NewPing(uint64 indexed requestId);

    // events we will emit while handling acknowledgement
    event ExecutionStatus(uint64 indexed eventIdentifier, bool isSuccess);
    event AckFromDestination(uint64 indexed requestId, string ackMessage);

    constructor(
        address payable gatewayAddress,
        uint64 _destGasLimit,
        uint64 _ackGasLimit,
        string memory feePayerAddress
    ) {
        owner = msg.sender;

        gatewayContract = IGateway(gatewayAddress);
        destGasLimit = _destGasLimit;
        ackGasLimit = _ackGasLimit;

        gatewayContract.setDappMetadata(feePayerAddress);
    }

    /// @notice function to set the fee payer address on Router Chain.
    /// @param feePayerAddress address of the fee payer on Router Chain.
    function setDappMetadata(string memory feePayerAddress) external {
        require(msg.sender == owner, "only owner");
        gatewayContract.setDappMetadata(feePayerAddress);
    }

    /// @notice function to set the Router Gateway Contract.
    /// @param gateway address of the gateway contract.
    function setGateway(address gateway) external {
        require(msg.sender == owner, "only owner");
        gatewayContract = IGateway(gateway);
    }

    /// @notice function to generate a cross-chain request to ping a destination chain contract.
    /// @param chainType chain type of the destination chain.
    /// @param chainId chain ID of the destination chain in string.
    /// @param destGasPrice gas price of the destination chain.
    /// @param ackGasPrice gas price of the source chain.
    /// @param destinationContractAddress contract address of the contract that will handle this
    /// request on the destination chain(in bytes format).
    /// @param str string we will be sending as greeting to the destination chain.
    /// @param expiryDurationInSeconds expiry duration of the request in seconds. After this time,
    /// if the request has not already been executed, it will fail on the destination chain.
    /// If you don't want to provide any expiry duration, send type(uint64).max in its place.
    function pingDestination(
        uint64 chainType,
        string memory chainId,
        uint64 destGasPrice,
        uint64 ackGasPrice,
        address destinationContractAddress,
        string memory str,
        uint64 expiryDurationInSeconds
    ) public payable {
        currentRequestId++;
        // creating the payload to be sent to the destination chain
        bytes memory payload = abi.encode(currentRequestId, str);

        Utils.DestinationChainParams memory destChainParams = Utils
            .DestinationChainParams(
                destGasLimit,
                destGasPrice,
                chainType,
                chainId,
                "" // asmAddress
            );

        Utils.AckGasParams memory ackGasParams = Utils.AckGasParams(
            ackGasLimit,
            ackGasPrice
        );

        Utils.RequestArgs memory requestArgs = Utils.RequestArgs(
            uint64(block.timestamp) + expiryDurationInSeconds,
            false
        );

        CrossTalkUtils.singleRequestWithAcknowledgement(
            address(gatewayContract),
            requestArgs,
            Utils.AckType.ACK_ON_SUCCESS,
            ackGasParams,
            destChainParams,
            CrossTalkUtils.toBytes(destinationContractAddress),
            payload
        );

        emit NewPing(currentRequestId);
    }

    /// @notice function to handle the cross-chain request received from some other chain.
    /// @param srcContractAddress address of the contract on source chain that initiated the request.
    /// @param payload the payload sent by the source chain contract when the request was created.
    /// @param srcChainId chain ID of the source chain in string.
    /// @param srcChainType chain type of the source chain.
    function handleRequestFromSource(
        bytes memory srcContractAddress,
        bytes memory payload,
        string memory srcChainId,
        uint64 srcChainType
    ) external override returns (bytes memory) {
        require(msg.sender == address(gatewayContract));

        (uint64 requestId, string memory sampleStr) = abi.decode(
            payload,
            (uint64, string)
        );

        if (
            keccak256(abi.encodePacked(sampleStr)) ==
            keccak256(abi.encodePacked(""))
        ) {
            revert CustomError("String should not be empty");
        }

        pingFromSource[srcChainType][srcChainId][requestId] = sampleStr;

        emit PingFromSource(srcChainType, srcChainId, requestId, sampleStr);

        return abi.encode(requestId, sampleStr);
    }

    /// @notice function to handle the acknowledgement received from the destination chain
    /// back on the source chain.
    /// @param eventIdentifier event nonce which is received when we create a cross-chain request
    /// We can use it to keep a mapping of which nonces have been executed and which did not.
    /// @param execFlags an array of boolean values suggesting whether the calls were successfully
    /// executed on the destination chain.
    /// @param execData an array of bytes returning the data returned from the handleRequestFromSource
    /// function of the destination chain.
    function handleCrossTalkAck(
        uint64 eventIdentifier,
        bool[] memory execFlags,
        bytes[] memory execData
    ) external override {
        bytes memory _execData = abi.decode(execData[0], (bytes));

        (uint64 requestId, string memory ackMessage) = abi.decode(
            _execData,
            (uint64, string)
        );

        ackFromDestination[requestId] = ackMessage;

        emit ExecutionStatus(eventIdentifier, execFlags[0]);
        emit AckFromDestination(requestId, ackMessage);
    }
}