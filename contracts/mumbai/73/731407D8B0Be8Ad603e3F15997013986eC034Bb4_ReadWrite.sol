/**
 *Submitted for verification at polygonscan.com on 2022-05-25
*/

//SPDX-License-Identifier: MIT

/*-----------------------------------------------------------
 @Filename:         ReadWrite.sol
 @Copyright Author: Yogesh Kulkarni @encode hackathon
 @Date:             25/05/2022
 @Description: Build a dApp to read and write from a smart contract with a front-end.
               This contract writes and reads a string from Polygon network
-------------------------------------------------------------*/
pragma solidity ^0.8.12;


contract ReadWrite {
    event UpdatedMessages(string oldStr, string newStr);
    string message;

    constructor(string memory _message) {
        message = _message;
    }

    function getMessage() public view returns (string memory) {
        return message;
    }

    function setMessage(string memory _newMessage) public {
        string memory oldMsg = message;
        message = _newMessage;
        emit UpdatedMessages(oldMsg, message);
    }
}