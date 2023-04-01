/**
 *Submitted for verification at polygonscan.com on 2023-03-30
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

contract dizzy_Last {
    
    string private lockedValue;
    address private owner;
    uint256 private unlockTime;
    address private walletAddr;
    
    constructor(string memory _value, address _walletAddr) {
        lockedValue = _value;
        owner = msg.sender;
        unlockTime = block.timestamp + 10 * 30 * 24 * 60 * 60; // lock for 10 months
        walletAddr = _walletAddr;
    }
    
    function open() public view returns (string memory) {
        require(msg.sender == owner, "Only the owner can open the lock");
        require(block.timestamp >= unlockTime, "The lock is not yet open"); //base64
        return lockedValue;
    }
    
    function wallAddress() public view returns (address) {
        return walletAddr;
    }
}