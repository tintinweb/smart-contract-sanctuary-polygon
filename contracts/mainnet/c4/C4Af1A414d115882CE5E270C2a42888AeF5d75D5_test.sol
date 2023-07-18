// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


contract test {

    uint256 internal amount;

    constructor() {}

    function setAmount( uint256 _amount ) public {
        amount = _amount;
    } 

    function getAmount () public view returns (uint256) {
        return amount;
    }
}