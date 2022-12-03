// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Box {
    uint public num;

    // constructor(uint _num) {
    //     num = _num;
    // }

    function __init(uint _num)
        public
    {
        num = _num;
    }
}