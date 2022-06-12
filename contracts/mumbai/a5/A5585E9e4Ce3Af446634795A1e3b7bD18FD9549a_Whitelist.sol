/**
 *Submitted for verification at polygonscan.com on 2022-06-11
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Whitelist {
    // Max number of Whitelisted addresses allowed
    // Create a mapping of WhitelistedAddresses
    // numAddressesWhitelisted would be used to keep track of how many addresses have been Whitelisted
    uint8 public maxWhitelistedAddresses;
    mapping(address => bool) public WhitelistedAddresses;
    uint8 public numAddressesWhitelisted;

    // Setting the Max number of Whitelisted addresses
    // User will put the value at the time of deployment
    constructor(uint8 _maxWhitelistedAddresses) {
        maxWhitelistedAddresses = _maxWhitelistedAddresses;
    }

    function addAddressToWhitelist() public {
        // check if the user has already been Whitelisted
        // check if the numAddressesWhitelisted < maxWhitelistedAddresses, if not then throw an error.
        require(
            !WhitelistedAddresses[msg.sender],
            "Sender has already been Whitelisted"
        );
        require(
            numAddressesWhitelisted < maxWhitelistedAddresses,
            "More addresses cant be added, limit reached"
        );
        // Add the address which called the function to the WhitelistedAddress array
        // Increase the number of Whitelisted addresses
        WhitelistedAddresses[msg.sender] = true;
        numAddressesWhitelisted += 1;
    }
}