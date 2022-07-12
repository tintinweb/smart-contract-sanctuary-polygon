/**
 *Submitted for verification at polygonscan.com on 2022-07-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

contract MessageContract {
    
    string public message;

    constructor(string memory _message) {
        message = _message;
    }

    function setMessage(string memory _message) public {
        message = _message;
    }
}