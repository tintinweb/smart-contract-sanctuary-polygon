//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract SMSContract{

    address owner;

    constructor() {
       owner = (msg.sender);
    }

    function Message(string memory _message) public pure returns(string memory){
        return _message;
    }
}