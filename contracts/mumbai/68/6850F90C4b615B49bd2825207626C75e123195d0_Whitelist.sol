//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

contract Whitelist {
    uint8 public maxWhitelistedAddresses;

    mapping(address => bool) public whitelistAddresses;

    uint8 public numAddressesWhitelisted;

    constructor(uint8 _maxWhitelistAddresses) {
        maxWhitelistedAddresses = _maxWhitelistAddresses;
    }

    function addAddressToWhitelist() public {
        require(
            !whitelistAddresses[msg.sender],
            "Sender has already been whitelisted"
        );
        require(
            numAddressesWhitelisted < maxWhitelistedAddresses,
            "More addresses cant be added, limit reached"
        );

        whitelistAddresses[msg.sender] = true;

        numAddressesWhitelisted += 1;
    }
}