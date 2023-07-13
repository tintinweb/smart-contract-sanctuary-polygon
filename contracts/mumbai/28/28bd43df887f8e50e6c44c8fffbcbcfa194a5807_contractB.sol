/**
 *Submitted for verification at polygonscan.com on 2023-07-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract contractB{

    uint public value;

    event UpdateValue(address indexed caller, uint indexed  Value);

    constructor() { }

    function eventFunc() external returns(bool){
        value = value + 5;
        emit UpdateValue(msg.sender, value);
        return true;

    }

    function calFunc() external returns(bool){
        value = value + 5;
        return true;
    }

}