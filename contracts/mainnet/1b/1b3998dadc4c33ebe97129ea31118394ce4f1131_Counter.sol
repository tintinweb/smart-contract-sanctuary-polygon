pragma solidity 0.8.14;

import {ITelepathyHandler, ITelepathyBroadcaster} from "src/amb/interfaces/ITelepathy.sol";

contract Counter is ITelepathyHandler {
    // We put together the sending the recieving counters instead of
    // separating them out for ease of use.

    uint256 public nonce;
    ITelepathyBroadcaster broadcaster;
    mapping(uint16 => address) public otherSideCounterMap;
    address otherSideCounter;
    address telepathyReceiver;

    event Incremented(uint256 indexed nonce, uint16 indexed chainId);

    constructor(ITelepathyBroadcaster _broadcaster, address _counter, address _telepathyReceiver) {
        // Only relevant for controlling counter
        broadcaster = _broadcaster;
        // This is only relevant for the recieving counter
        otherSideCounter = _counter;
        telepathyReceiver = _telepathyReceiver;
        nonce = 1;
    }

    // Controlling counter functions

    // Relevant for controlling counter
    function setSourceAMB(ITelepathyBroadcaster _broadcaster) external {
        broadcaster = _broadcaster;
    }

    // Relevant for controlling counter
    function setOtherSideCounterMap(uint16 chainId, address counter) external {
        otherSideCounterMap[chainId] = counter;
    }

    function increment(uint16 chainId) external {
        nonce++;
        require(otherSideCounterMap[chainId] != address(0), "Counter: otherSideCounter not set");
        broadcaster.send(chainId, otherSideCounterMap[chainId], abi.encode(nonce));
        emit Incremented(nonce, chainId);
    }

    function incrementViaLog(uint16 chainId) external {
        nonce++;
        require(otherSideCounterMap[chainId] != address(0), "Counter: otherSideCounter not set");
        broadcaster.sendViaLog(chainId, otherSideCounterMap[chainId], abi.encode(nonce));
        emit Incremented(nonce, chainId);
    }

    // Receiving counter functions

    /// @notice Set the address of the Telepathy Receiver contract
    function setTelepathyReceiver(address _telepathyReceiver) external {
        telepathyReceiver = _telepathyReceiver;
    }

    function setOtherSideCounter(address _counter) external {
        otherSideCounter = _counter;
    }

    /// @notice handleTelepathy is called by the Telepathy Receiver when a message is executed
    /// @dev We do not enforce any checks on the `_srcChainId` since we want to allow the counter
    /// to receive messages from any chain
    function handleTelepathy(uint16, address _senderAddress, bytes memory _data) external {
        require(msg.sender == telepathyReceiver);
        require(_senderAddress == otherSideCounter);
        (uint256 _nonce) = abi.decode(_data, (uint256));
        nonce = _nonce;
        emit Incremented(nonce, uint16(block.chainid));
    }
}

pragma solidity 0.8.14;

import "src/lightclient/interfaces/ILightClient.sol";

interface ITelepathyBroadcaster {
    event SentMessage(uint256 indexed nonce, bytes32 indexed msgHash, bytes message);

    function send(uint16 _recipientChainId, bytes32 _recipientAddress, bytes calldata _data)
        external
        returns (bytes32);

    function send(uint16 _recipientChainId, address _recipientAddress, bytes calldata _data)
        external
        returns (bytes32);

    function sendViaLog(uint16 _recipientChainId, bytes32 _recipientAddress, bytes calldata _data)
        external
        returns (bytes32);

    function sendViaLog(uint16 _recipientChainId, address _recipientAddress, bytes calldata _data)
        external
        returns (bytes32);
}

enum MessageStatus {
    NOT_EXECUTED,
    EXECUTION_FAILED,
    EXECUTION_SUCCEEDED
}

struct Message {
    uint256 nonce;
    uint16 sourceChainId;
    address senderAddress;
    uint16 recipientChainId;
    bytes32 recipientAddress;
    bytes data;
}

interface ITelepathyReceiver {
    event ExecutedMessage(
        uint256 indexed nonce, bytes32 indexed msgHash, bytes message, bool status
    );

    function executeMessage(
        uint64 slot,
        bytes calldata message,
        bytes[] calldata accountProof,
        bytes[] calldata storageProof
    ) external;

    function executeMessageFromLog(
        bytes calldata srcSlotTxSlotPack,
        bytes calldata messageBytes,
        bytes32[] calldata receiptsRootProof,
        bytes32 receiptsRoot,
        bytes[] calldata receiptProof, // receipt proof against receipt root
        bytes memory txIndexRLPEncoded,
        uint256 logIndex
    ) external;
}

interface ITelepathyHandler {
    function handleTelepathy(uint16 _sourceChainId, address _senderAddress, bytes memory _data)
        external;
}

pragma solidity 0.8.14;

interface ILightClient {
    function consistent() external view returns (bool);

    function head() external view returns (uint256);

    function headers(uint256 slot) external view returns (bytes32);

    function executionStateRoots(uint256 slot) external view returns (bytes32);

    function timestamps(uint256 slot) external view returns (uint256);
}