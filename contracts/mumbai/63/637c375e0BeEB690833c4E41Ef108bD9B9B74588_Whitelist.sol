/**
 *Submitted for verification at polygonscan.com on 2023-07-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Whitelist {
    // variable to set if an address is whitelisted or not
    mapping(address => bool) public whitelist;
    // address anyAddres; bool default value is false
    // function to add an address to the whitelist

    function addToWhitelist (address _address) public {
        require(_address != address(0), "Invalid address.");
        require(whitelist[_address] != true, "Address already whitelisted.");

        whitelist[_address] = true; 
    }

    // function to remove an address from the whitelist
    function removeFromWhitelist (address _address) public {
        require(_address != address(0), "Invalid address");
        require(whitelist[_address] == true, "Address not on the whitelist");

        whitelist[_address] = false;
    }

    // function to check if an address is whitelisted or not
    // (view state mutability) pure is not reading nor writing; view is reading only & not able to change it
    function isWhitelisted (address _address) public view returns (bool _isWhitelisted) {
        return whitelist[_address];
    }

    // modifier to restrict functions to whitelisted addresses
    modifier onlyWhitelisted () {
        // enter the logic here
        require(whitelist[msg.sender], "You are not whitelisted.");
        _;
    }
}