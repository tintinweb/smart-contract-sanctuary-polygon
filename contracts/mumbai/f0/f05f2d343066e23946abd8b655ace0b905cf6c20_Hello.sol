/**
 *Submitted for verification at polygonscan.com on 2022-06-09
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
        subject = _subject;
        emit LogString(subject);
        emit LogSender(sender);
    }

}