// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Whitelist {

    uint8 public maxWhitelistedAddresses;

    uint8 public numAddressesWhitelisted;

    mapping(address => bool) public whitelistAddresses;

    constructor(uint8 _maxWhitelistedAddresses) {
        maxWhitelistedAddresses = _maxWhitelistedAddresses;
    }

    function addAddressToWhitelist() public {

        require(whitelistAddresses[msg.sender] == false, "Address already whitelisted");
        require(numAddressesWhitelisted < maxWhitelistedAddresses, "Whitelist is full");

        whitelistAddresses[msg.sender] = true;

        numAddressesWhitelisted++;

    }

    function removeAddressFromWhitelist() public {

        require(whitelistAddresses[msg.sender] == true, "Address not whitelisted");

        whitelistAddresses[msg.sender] = false;

        numAddressesWhitelisted--;

    }

    function isAddressWhitelisted(address _address) public view returns (bool) {

        return whitelistAddresses[_address];

    }

}