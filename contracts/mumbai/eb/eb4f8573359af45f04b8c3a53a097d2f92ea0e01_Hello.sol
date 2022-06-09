/**
 *Submitted for verification at polygonscan.com on 2022-06-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.14;

contract Hello{
    event LogString(string logString);
    event LogSender(address logSender);
    event LogData(bytes logData);

    function hello(string memory _log) public returns(string memory){
        emit LogString(_log);
        emit LogSender(msg.sender);
        emit LogData(msg.data);
        return "I'm in";
    }

}