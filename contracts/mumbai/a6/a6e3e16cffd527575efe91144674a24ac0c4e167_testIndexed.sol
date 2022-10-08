/**
 *Submitted for verification at polygonscan.com on 2022-10-07
*/

// SPDX-License-Identifier: MIT
// File: transferTest_flat.sol



pragma solidity  ^0.8.4;

contract testIndexed {
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    function callTransfer(address _to) public {
        emit Transfer(msg.sender, _to, 1000000000);
    }
    
}