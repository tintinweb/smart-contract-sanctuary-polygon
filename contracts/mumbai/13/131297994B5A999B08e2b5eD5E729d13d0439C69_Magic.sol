// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Magic {
    uint public magicNumber;

    event Increase(uint from, uint to);
    event Decrease(uint from, uint to);

    constructor() payable {}

    function _increase() public {
        uint oldNumber = magicNumber;
        magicNumber++;
        emit Increase(oldNumber, magicNumber);
    }

    function _decrease() public {
        uint oldNumber = magicNumber;
        magicNumber--;
        emit Decrease(oldNumber, magicNumber);
    }

    function setMagicNumber(uint x) public {
        magicNumber = x;
    }

    function set_magic_number(uint x) public {
        magicNumber = x;
    }
}