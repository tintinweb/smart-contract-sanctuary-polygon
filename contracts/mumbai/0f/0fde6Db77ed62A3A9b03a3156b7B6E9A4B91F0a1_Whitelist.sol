// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Whitelist {
    uint8 private immutable maxWhitelistedAddresses;
    mapping(address => bool) private whitelistedAddresses;
    uint8 public numAddressesWhitelisted;

    constructor(uint8 _maxWhitelistedAddresses) {
        maxWhitelistedAddresses = _maxWhitelistedAddresses;
    }

    function addAddressToWhitelist() public {
        // check if the user has already been whitelisted
        require(
            !whitelistedAddresses[msg.sender],
            "Sender has already been whitelisted"
        );
        // check if the numAddressesWhitelisted < maxWhitelistedAddresses, if not then throw an error.
        require(
            numAddressesWhitelisted < maxWhitelistedAddresses,
            "More addresses cant be added, limit reached"
        );
        // Add the address which called the function to the whitelistedAddress array
        whitelistedAddresses[msg.sender] = true;
        // Increase the number of whitelisted addresses
        numAddressesWhitelisted += 1;
    }

    function isWhitelistedAddresses(address addr) external view returns (bool) {
        return whitelistedAddresses[addr];
    }

    function getMaxWhitelistedAddresses() external view returns (uint8) {
        return maxWhitelistedAddresses;
    }

    function getNumAddressesWhitelisted() external view returns (uint8) {
        return numAddressesWhitelisted;
    }
}