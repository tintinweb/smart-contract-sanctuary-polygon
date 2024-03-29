/**
 *Submitted for verification at polygonscan.com on 2023-07-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Whitelist {
    //variable to set if an address is whitelisted or not
    mapping(address => bool) private whitelist;

    //function to add an address to the whitelist
    function addToWhitelist (address _address) external {
        require(_address != address(0), "Invalid address.");
        require(whitelist[_address] != true, "Address already whitelisted.");

        whitelist[_address] = true;
    }

    //function to remove an address from the whitelist
    function removeFromWhitelist(address _address) external onlyWhitelisted {
        require(_address != address(0), "Invalid address.");
        require(whitelist[_address] != true, "Address not on the whitelist.");

        whitelist[_address] = false;
    }

    //function to check if an address is whitelisted or not
    function isWhitelisted(address _address) external view returns(bool _isWhitelisted) {
        return whitelist[_address];
    }

    //modifier to restrict functions to whitelisted addresses
    modifier onlyWhitelisted() {
        //enetr the logic here
        require(whitelist[msg.sender], "You are not whitelisted.");
        _;
    }
}