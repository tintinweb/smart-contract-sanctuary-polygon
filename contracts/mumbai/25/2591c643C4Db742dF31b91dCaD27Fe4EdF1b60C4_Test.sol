// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Test {
    uint256 public magicNumber = 1;

    function setMagicNumber(uint256 _magicNumber) public {
        magicNumber = _magicNumber;
    }

    function increaseMagicNumber() public {
        magicNumber++;
    }
}