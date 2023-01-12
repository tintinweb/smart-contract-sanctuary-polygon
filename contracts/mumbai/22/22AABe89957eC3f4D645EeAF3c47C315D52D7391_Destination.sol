// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

contract Destination {

    string public Message = "Hi";

    event NewMsg(string Message);

    function anyExecute(bytes memory _data) external returns (bool success, bytes memory result){
        (string memory _Message) = abi.decode(_data, (string));

        Message = _Message;
        emit NewMsg(Message);
        
        success=true;
        result='';
    }
}