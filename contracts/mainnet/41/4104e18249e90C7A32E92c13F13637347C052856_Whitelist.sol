// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;


contract Whitelist {

    mapping(address => bool) public whitelistedAddresses;
    uint8 public numAddressesWhitelisted;

    constructor() {
    }

    function addAddressToWhitelist() public {
        require(!whitelistedAddresses[msg.sender], "Sender has already been whitelisted");
        whitelistedAddresses[msg.sender] = true;
        numAddressesWhitelisted += 1;
    }

}