/**
 *Submitted for verification at polygonscan.com on 2022-06-09
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Waitlist {
    // Max number of waitlisted addresses allowed
    // Create a mapping of waitlistedAddresses
    // numAddresseswaitlisted would be used to keep track of how many addresses have been waitlisted
    uint8 public maxWaitlistedAddresses;
    mapping(address => bool) public waitlistedAddresses;
    uint8 public numAddressesWaitlisted;

    // Setting the Max number of waitlisted addresses
    // User will put the value at the time of deployment
    constructor(uint8 _maxWaitlistedAddresses) {
        maxWaitlistedAddresses = _maxWaitlistedAddresses;
    }

    function addAddressToWaitlist() public {
        // check if the user has already been waitlisted
        // check if the numAddressesWaitlisted < maxWaitlistedAddresses, if not then throw an error.
        require(
            !waitlistedAddresses[msg.sender],
            "Sender has already been waitlisted"
        );
        require(
            numAddressesWaitlisted < maxWaitlistedAddresses,
            "More addresses cant be added, limit reached"
        );
        // Add the address which called the function to the waitlistedAddress array
        // Increase the number of waitlisted addresses
        waitlistedAddresses[msg.sender] = true;
        numAddressesWaitlisted += 1;
    }
}