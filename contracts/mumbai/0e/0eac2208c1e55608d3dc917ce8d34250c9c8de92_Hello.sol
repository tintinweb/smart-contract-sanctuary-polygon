/**
 *Submitted for verification at polygonscan.com on 2022-06-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.14;

contract Hello{
    string public subject;
    address public sender;
    
    event LogString(string logString);
    event LogSender(address logSender);

    function hello(string memory _subject) public {
        sender = msg.sender;
        subject = string.concat(string(abi.encodePacked(msg.sender)), _subject);
        emit LogString(subject);
    }

}