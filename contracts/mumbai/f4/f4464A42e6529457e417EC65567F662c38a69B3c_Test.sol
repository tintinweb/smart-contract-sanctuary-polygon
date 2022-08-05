// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// A sample contract
contract Test {
    uint public var1;
    address public var2;

    event Withdrawal(uint amount, uint when);

    constructor(uint _var1, address _var2) {
        var1 = _var1;
        var2 = _var2;
    }

    function setVar1(uint _var1) public {
        var1 = _var1;
    }
}