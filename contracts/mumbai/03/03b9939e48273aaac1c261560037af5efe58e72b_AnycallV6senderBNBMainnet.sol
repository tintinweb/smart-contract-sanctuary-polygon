/**
 *Submitted for verification at polygonscan.com on 2022-12-07
*/

/**
 *Submitted for verification at BscScan.com on 2022-05-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface CallProxy{
    function anyCall(
        address _to,
        bytes calldata _data,
        address _fallback,
        uint256 _toChainID,
        uint256 _flags

    ) external;
}

  

contract AnycallV6senderBNBMainnet{

    // The Multichain anycall contract on bnb mainnet
    address private anycallcontractbnb=0x8E680018D67C57889083c23786C225F730C54Fb5;


    address private owneraddress=0x6f1a558DEc5F483848C3D87aC4EB1C2Bd46Ee1bE;

    // Destination contract on Polygon
    address private receivercontract=0x3E2347a6F93eaC793C56DC508206e397eA11e83D;
    
    modifier onlyowner() {
        require(msg.sender == owneraddress, "only owner can call this method");
        _;
    }

    event NewMsg(string msg);

    function changereceivercontract(address newreceiver) external onlyowner {
        receivercontract=newreceiver;
    }

    function step1_initiateAnyCallSimple(string calldata _msg) external {
        emit NewMsg(_msg);
        if (msg.sender == owneraddress){
        CallProxy(anycallcontractbnb).anyCall(
            receivercontract,

            // sending the encoded bytes of the string msg and decode on the destination chain
            abi.encode(_msg),

            // 0x as fallback address because we don't have a fallback function
            address(0),

            // chainid of polygon
            4002,

            // Using 0 flag to pay fee on destination chain
            2
            );
            
        }

    }
}