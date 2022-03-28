/**
 *Submitted for verification at polygonscan.com on 2022-03-27
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Test {
    constructor() {}

    function addCD(string calldata message_) public {
        emit TextMessage(msg.sender, msg.sender, message_);
    }

    function addM(string memory message_) public {
        emit TextMessage(msg.sender, msg.sender, message_);
    }

    event TextMessage(
        address indexed from_,
        address indexed to_,
        string message_
    );
}