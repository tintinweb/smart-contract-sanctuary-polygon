// SPDX-License-Identifier: None
pragma solidity ^0.8.10;
import "./IBridge.sol";

contract Bridge is IBridge {
    address public owner;
    address public relayer;

    // address of sending contract + recieving contract => nonce
    // this will be updated everytime a request to relay a message is received
    mapping(address => mapping(address => uint256)) public nonceForRecievingCounter;

    // address of sending contract + nonce => executed or not boolean
    // this will be used on the destination side to update which nonces are executed already
    mapping(address => mapping(uint256 => bool)) public executed;

    // This is emitted when the a request to relay a message is received
    event RequestToRelay(bytes data, uint256 nonce, address indexed sendingCounter, address indexed receivingCounter);

    // This is emitted when the transaction is executed on the destination chain
    event Execute(
        address indexed sendingCounter,
        address indexed recievingCounter,
        uint256 indexed nonce,
        bool success
    );

    constructor(address _relayer) {
        require(_relayer != address(0), "Relayer can't be address(0)");
        owner = msg.sender;
        relayer = _relayer;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    /// @notice Function to set the relayer.
    /// @notice Only the owner wallet can call this function.
    /// @param _relayer Address of the new relayer.
    function setRelayer(address _relayer) external onlyOwner {
        relayer = _relayer;
    }

    /// @notice Function to set the owner.
    /// @notice Only the owner wallet can call this function.
    /// @param _owner Address of the new owner.
    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    /// @notice Function to send a request to relay a message.
    /// @notice This function is called when a request is recieved to relay a message to the destination chain.
    /// @param recievingCounter Address of the recipient contract on destination chain.
    /// @param data Calldata to be passed to the recievingCounter contract on the destination chain.
    function send(address recievingCounter, bytes calldata data) public {
        // nonce updated for the pair of sending counter and recieving counter contract
        nonceForRecievingCounter[msg.sender][recievingCounter] += 1;
        emit RequestToRelay(data, nonceForRecievingCounter[msg.sender][recievingCounter], msg.sender, recievingCounter);
    }

    /// @notice Function to recieve a request to relay a message on the destination chain.
    /// @notice This function is called when the relayer calls the destination chain to relay a message.
    /// @notice Only the relayer wallet can call it.
    /// @param recievingCounter Address of the recipient contract on destination chain.
    /// @param data Calldata to be passed to the recievingCounter contract on the destination chain.
    function recieve(
        address sendingCounter,
        uint256 nonce,
        address recievingCounter,
        bytes calldata data
    ) public {
        require(msg.sender == relayer, "only relayer");
        require(!executed[sendingCounter][nonce], "nonce already executed");
        executed[sendingCounter][nonce] = true;

        // executing the request on the recieving counter contract
        // solhint-disable
        (bool success, ) = recievingCounter.call(data);
        require(success, "Unsuccessful");

        emit Execute(sendingCounter, recievingCounter, nonce, success);
    }
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.10;

interface IBridge {
    function send(address recievingCounter, bytes calldata data) external;
}