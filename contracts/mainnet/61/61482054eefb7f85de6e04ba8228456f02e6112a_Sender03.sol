/**
 *Submitted for verification at polygonscan.com on 2022-06-17
*/

// SPDX-License-Identifier: GLWTPL

pragma solidity ^0.8.14;

interface CallProxy {
    function anyCall(
        address _to,
        bytes calldata _data,
        address _fallback,
        uint256 _toChainID,
        uint256 _flags
    ) external payable;
}

// Polygon mainnet
contract Sender03 {

    // The Multichain anycall contract on mainnet
    address private anycallContractMainnet = 0xC10Ef9F491C9B59f936957026020C321651ac078;

    address owner;

    // Destination contract on Fantom mainnet
    address receiverContract;

    // Destination chain id
    uint256 destinationChainId = 250;

    event SendNumber(uint256 number);

    event AnyFallbackCalled();
    event AnyExecuteCalled();
    event StandardReceiveCalled();
    event StandardFallbackCalled();

    constructor() {
        owner = msg.sender;
    }

    function setReceiverContract(address _receiverContract) external {
        require(msg.sender == owner);

        receiverContract = _receiverContract;
    }

    function send(uint256 _number) external payable {
        emit SendNumber(_number);

        require(receiverContract != address(0), "receiverContract");
        require(destinationChainId != 0, "destinationChainId");

        CallProxy(anycallContractMainnet).anyCall{value : msg.value}(
            receiverContract,
            abi.encode(_number),
            address(this),
            destinationChainId,
            2 // fees paid on source chain
        );
    }

    function anyFallback(address, bytes calldata) public {
        emit AnyFallbackCalled();
    }

    function anyExecute(bytes memory) external returns (bool success, bytes memory result) {
        emit AnyExecuteCalled();

        success = true;
        result = '';
    }

    receive() external payable {
        emit StandardReceiveCalled();
    }

    fallback() external payable {
        emit StandardFallbackCalled();
    }

    function cleanup() external {
        require(msg.sender == owner);

        payable(msg.sender).transfer(address(this).balance);
    }
}