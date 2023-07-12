/**
 *Submitted for verification at polygonscan.com on 2023-07-11
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

contract SimpleStorageString {
    string private text;

    constructor() {
        text = "Z";
    }

    function Set(string memory _text) public {
        text = _text;
    }

    function Get() public view returns (string memory) {
        return text;
    }
}