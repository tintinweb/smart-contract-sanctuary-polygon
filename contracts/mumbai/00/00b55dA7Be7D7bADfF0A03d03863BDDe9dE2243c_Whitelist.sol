//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

contract Whitelist {

    uint8 public maxWhitelistedAddresses;

    mapping (address => bool) public whitelistedAddresses;

    uint8 public numAddressesWhitelisted;


     constructor(uint8 _maxWhitelistedAddresses) {
        maxWhitelistedAddresses =  _maxWhitelistedAddresses;
    }

        function addAddressToWhitelist() public {

        // check if the user has already been whitelisted
        require(!whitelistedAddresses[msg.sender], "Sender has already been whitelisted");

        // check if the numAddressesWhitelisted < maxWhitelistedAddresses, if not then throw an error.
        require(numAddressesWhitelisted < maxWhitelistedAddresses, "More addresses cant be added, limit reached");
        
        // Add the address which called the function to the whitelistedAddress array
        whitelistedAddresses[msg.sender] = true;
        
        // Increase the number of whitelisted addresses
        numAddressesWhitelisted += 1;
    }

}