// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FxBaseChildTunnel.sol";


contract ChildMATIC is FxBaseChildTunnel {

    address public latestContractAddress;
    address public latestSenderAddress;
    uint256 public latestTimeData;
    uint256 public timeReceived;
    string public latestMessage;
    string[] public listOfMessages;
    bool public msgReceived = false;

    constructor(address _fxChild) FxBaseChildTunnel(_fxChild){

    }


    function _processMessageFromRoot(uint256 stateId, address sender, bytes memory data) internal override validateSender(sender){
        latestContractAddress = sender;
        (latestSenderAddress, latestMessage,latestTimeData) = abi.decode(data, (address, string, uint256));


        timeReceived = block.timestamp; //In seconds
        msgReceived = true;

        //Store the list of messages in an array
        listOfMessages.push(latestMessage);
    }

    function calculateTransferDuration() public view returns(uint256){
        return timeReceived - latestTimeData; //In seconds
    }

    function resetTimeData() public {
        latestTimeData = 0;
        timeReceived = 0;
        msgReceived = false;
    }

    // function setFxRootTunnel(address _fxRootTunnel) external override {
    //     fxRootTunnel = _fxRootTunnel;
    // }


    
}