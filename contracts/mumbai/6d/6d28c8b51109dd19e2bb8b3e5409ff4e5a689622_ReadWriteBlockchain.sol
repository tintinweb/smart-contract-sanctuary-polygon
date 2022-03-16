/**
 *Submitted for verification at polygonscan.com on 2022-03-15
*/

// SPDX-License-Identifier: MIT
pragma solidity  0.8.9;

contract ReadWriteBlockchain {
    string str;

    constructor(string memory initMessage) {
        str = initMessage;
    }

    function set(string calldata _text) public {
        str = _text;
    }

    function get() public view returns (string memory) {
        return str;
    }
}