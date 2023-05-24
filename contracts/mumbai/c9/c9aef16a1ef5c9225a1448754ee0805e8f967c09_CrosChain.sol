/**
 *Submitted for verification at polygonscan.com on 2023-05-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CrosChain {
    string private _address;
    address private _owner;
    constructor() {
        _owner = msg.sender;
    }
    function Transfer(string memory _to) public  {
        require(_owner == msg.sender);
        _address = _to;
    }
}