//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


contract CrookedSnoutsWhitelist {

    uint16 public maxWhitelistedAddresses;
    uint16 public numAddressesWhitelisted;
    uint256 public whitelistClose;

    mapping(address => bool) public whitelistedAddresses;


    constructor() {
        maxWhitelistedAddresses = 500;
        whitelistClose = block.timestamp + 21 days;
    }

    function addAddressToWhitelist() public {
        require(!whitelistedAddresses[msg.sender], "Sender is already whitelisted");
        require(numAddressesWhitelisted < maxWhitelistedAddresses, "Whitelisted addresses limit reached");
        require(block.timestamp <= whitelistClose, "Whitelist closed");

        whitelistedAddresses[msg.sender] = true;
        numAddressesWhitelisted += 1;
    }


}