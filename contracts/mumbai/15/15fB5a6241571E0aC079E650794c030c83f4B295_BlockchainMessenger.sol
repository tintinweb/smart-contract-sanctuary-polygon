/**
 *Submitted for verification at polygonscan.com on 2022-12-15
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

contract BlockchainMessenger {

    uint public changeCounter;

    address public owner;

    string public theMessage;

    constructor() {
        owner = msg.sender;
    }

    function updateTheMessage(string memory _newMessage) public {
        if(msg.sender == owner) {
            theMessage = _newMessage;
            changeCounter++;
        }
    }
}