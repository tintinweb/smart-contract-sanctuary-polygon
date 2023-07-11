/**
 *Submitted for verification at polygonscan.com on 2023-07-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


contract CrispyPOC{
    string message = "Hello World";

    constructor(){}

    function setMessage(string memory _message) public {
        message = _message;
    }

    function getMessage() public view returns(string memory) {
        return message;
    }
}