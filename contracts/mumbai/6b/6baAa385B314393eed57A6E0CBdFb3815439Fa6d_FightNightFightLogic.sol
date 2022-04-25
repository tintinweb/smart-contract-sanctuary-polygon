// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract FightNightFightLogic {
    constructor() {}

    string public name = "Fight Night Fight Logic";
    uint randNonce = 0;

    function randMod(uint _modulus) internal returns(uint) {
        randNonce++; 
        return uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % _modulus;
    }

    function fight() public returns(uint) {
        return randMod(100);
    }
}