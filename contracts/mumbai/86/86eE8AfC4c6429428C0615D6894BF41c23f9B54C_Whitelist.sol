// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Whitelist {
    uint8 public maxWhitelistedAddresses;

    uint8 public numAddressesWhitelisted;

    mapping(address => bool) public whitelistedAddresses;

    constructor(uint8 _maxWhitelistedAdddresses) {
        maxWhitelistedAddresses = _maxWhitelistedAdddresses;
    }

    function addressToWhitelisted() public {
        require(
            !whitelistedAddresses[msg.sender],
            "Sender already in the whitellist"
        );
        require(
            numAddressesWhitelisted < maxWhitelistedAddresses,
            "Max Limit reached"
        );
        whitelistedAddresses[msg.sender] = true;
        numAddressesWhitelisted += 1;
    }
}