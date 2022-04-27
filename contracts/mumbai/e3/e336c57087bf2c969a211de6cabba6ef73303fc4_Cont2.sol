/**
 *Submitted for verification at polygonscan.com on 2022-04-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Cont2 {
    uint _time;
    constructor (){
        _time = block.timestamp;
    }

    function test() view public returns(uint) {
        return _time;
    }
}