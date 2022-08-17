/**
 *Submitted for verification at polygonscan.com on 2022-08-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Lock {
    
    uint public x;
    event XChanged(address Addr, uint xVal);

    function setX(uint _x) external {
        x = _x;
        emit XChanged(msg.sender, x);
    }

    function getX() view public returns (uint) {
        return x;
    }
    
}