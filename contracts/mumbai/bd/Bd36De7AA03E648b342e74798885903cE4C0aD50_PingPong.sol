// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Utils.sol";

/**
 * @dev Interface of the Gateway Self External Calls.
 */
interface IGateway {
    // requestMetadata = abi.encodePacked(
    //     uint256 destGasLimit;
    //     uint256 destGasPrice;
    //     uint256 ackGasLimit;
    //     uint256 ackGasPrice;
    //     uint256 relayerFees;
    //     uint8 ackType;
    //     bool isReadCall;
    //     bytes asmAddress;
    // )

    function iSend(
        uint256 version,
        uint256 routeAmount,
        string calldata routeRecipient,
        string calldata destChainId,
        bytes calldata requestMetadata,
        bytes calldata requestPacket
    ) external payable returns (uint256);

    function setDappMetadata(string memory feePayerAddress) external payable returns (uint256);

    function crossChainRequestDefaultFee() external view returns (uint256 fees);

    function currentVersion() external view returns (uint256);
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
        uint256 valsetNonce;
    }

    struct RequestPayload {
        uint256 routeAmount;
        uint256 requestIdentifier;
        uint256 requestTimestamp;
        string srcChainId;
        address routeRecipient;
        string destChainId;
        address asmAddress;
        string requestSender;
        address handlerAddress;
        bytes packet;
        bool isReadCall;
    }

    struct CrossChainAckPayload {
        uint256 requestIdentifier;
        uint256 ackRequestIdentifier;
        string destChainId;
        address requestSender;
        bytes execData;
        bool execFlag;
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
    error InvalidValsetNonce(uint256 newNonce, uint256 currentNonce);
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

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "@routerprotocol/evm-gateway-contracts/contracts/IGateway.sol";

/// @title PingPong
/// @author Yashika Goyal
/// @notice This is a cross-chain ping pong smart contract to demonstrate how one can
/// utilise Router CrossTalk for cross-chain transactions.
contract PingPong {
    address public owner;
    uint64 public currentRequestId;

    struct RequestMetadata {
        uint256 destGasLimit;
        uint256 destGasPrice;
        uint256 ackGasLimit;
        uint256 ackGasPrice;
        uint256 relayerFees;
        Utils.AckType ackType;
        bool isReadCall;
        bytes asmAddress;
    }

    // srcChainId + requestId => pingFromSource
    mapping(string => mapping(uint64 => string)) public pingFromSource;
    // requestId => ackMessage
    mapping(uint64 => string) public ackFromDestination;

    // instance of the Router's gateway contract
    IGateway public gatewayContract;

    // custom error so that we can emit a custom error message
    error CustomError(string message);

    // event we will emit while sending a ping to destination chain
    event PingFromSource(
        string indexed srcChainId,
        uint64 indexed requestId,
        string message
    );
    event NewPing(uint64 indexed requestId);

    // events we will emit while handling acknowledgement
    event ExecutionStatus(uint256 indexed eventIdentifier, bool isSuccess);
    event AckFromDestination(uint64 indexed requestId, string ackMessage);

    constructor(address payable gatewayAddress, string memory feePayerAddress) {
        owner = msg.sender;

        gatewayContract = IGateway(gatewayAddress);

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
    /// @param destChainId chain ID of the destination chain in string.
    /// @param destinationContractAddress contract address of the contract that will handle this
    /// @param str string to be pinged to destination
    /// @param requestMetadata abi-encoded metadata according to source and destination chains
    function iPing(
        string calldata destChainId,
        string calldata destinationContractAddress,
        string calldata str,
        bytes calldata requestMetadata
    ) public payable {
        currentRequestId++;

        bytes memory packet = abi.encode(currentRequestId, str);
        bytes memory requestPacket = abi.encode(destinationContractAddress, packet);
        gatewayContract.iSend{ value: msg.value }(
            1,
            0,
            string(""),
            destChainId,
            requestMetadata,
            requestPacket
        );
        emit NewPing(currentRequestId);
    }

    /// @notice function to get the request metadata to be used while initiating cross-chain request
    /// @return requestMetadata abi-encoded metadata according to source and destination chains
    function getRequestMetadata(
        uint64 destGasLimit,
        uint64 destGasPrice,
        uint64 ackGasLimit,
        uint64 ackGasPrice,
        uint128 relayerFees,
        uint8 ackType,
        bool isReadCall,
        bytes memory asmAddress
    ) public pure returns (bytes memory) {
        bytes memory requestMetadata = abi.encodePacked(
            destGasLimit,
            destGasPrice,
            ackGasLimit,
            ackGasPrice,
            relayerFees,
            ackType,
            isReadCall,
            asmAddress
        );
        return requestMetadata;
    }

    /// @notice function to handle the cross-chain request received from some other chain.
    /// @param requestSender address of the contract on source chain that initiated the request.
    /// @param packet the payload sent by the source chain contract when the request was created.
    /// @param srcChainId chain ID of the source chain in string.
    function iReceive(
        string memory requestSender,
        bytes memory packet,
        string memory srcChainId
    ) external returns (uint64, string memory) {
        require(msg.sender == address(gatewayContract), "only gateway");
        (uint64 requestId, string memory sampleStr) = abi.decode(
            packet,
            (uint64, string)
        );
        pingFromSource[srcChainId][requestId] = sampleStr;

        emit PingFromSource(srcChainId, requestId, sampleStr);

        return (requestId, sampleStr);
    }

    /// @notice function to handle the acknowledgement received from the destination chain
    /// back on the source chain.
    /// @param requestIdentifier event nonce which is received when we create a cross-chain request
    /// We can use it to keep a mapping of which nonces have been executed and which did not.
    /// @param execFlag a boolean value suggesting whether the call was successfully
    /// executed on the destination chain.
    /// @param execData returning the data returned from the handleRequestFromSource
    /// function of the destination chain.
    function iAck(
        uint256 requestIdentifier,
        bool execFlag,
        bytes memory execData
    ) external {
        (uint64 requestId, string memory ackMessage) = abi.decode(
            execData,
            (uint64, string)
        );

        ackFromDestination[requestId] = ackMessage;

        emit ExecutionStatus(requestIdentifier, execFlag);
        emit AckFromDestination(requestId, ackMessage);
    }

    // Encode Fx
    function EncodeRequestMetadata(
        uint256 destGasLimit,
        uint256 destGasPrice,
        uint256 ackGasLimit,
        uint256 ackGasPrice,
        uint256 relayerFees,
        Utils.AckType ackType,
        bool isReadCall,
        bytes memory asmAddress
    ) external view returns (bytes memory ) {
        RequestMetadata memory _raw = RequestMetadata( destGasLimit , destGasPrice , ackGasLimit , ackGasPrice , relayerFees , ackType , isReadCall , asmAddress );
        return abi.encode(_raw);
    }
}