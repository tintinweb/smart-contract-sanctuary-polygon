// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;


contract Test {

    uint a;

    function setA (uint _a) public {
        a = _a;
    }

    function getA () public view returns(uint) {
        return a;
    }

}