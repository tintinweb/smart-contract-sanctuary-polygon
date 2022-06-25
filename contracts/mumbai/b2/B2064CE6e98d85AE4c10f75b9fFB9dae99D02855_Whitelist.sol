// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Whitelist {

    uint8 public maxWhitelistedAddr;

    mapping(address => bool) public isWhitelisted;

    uint8 public numAddrWhitelisted;

    constructor(uint8 _maxWhitelistedAddr) {
        maxWhitelistedAddr = _maxWhitelistedAddr;
    }

    function addAddrToWhitelist() public {
        require(!isWhitelisted[msg.sender], "sender already whitelisted");
        require(numAddrWhitelisted < maxWhitelistedAddr, "whitelist limit reached");
        
        isWhitelisted[msg.sender] = true;
        
        numAddrWhitelisted += 1;
    }

}