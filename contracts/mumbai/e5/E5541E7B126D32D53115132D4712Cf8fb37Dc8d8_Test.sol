// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract Test {
    uint number;

    function setter(uint _num) public {
        number = _num;
    }

    function getter() public view returns(uint) {
        return number;
    }
}