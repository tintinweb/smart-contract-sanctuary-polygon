/**
 *Submitted for verification at polygonscan.com on 2023-07-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Whitelist{
    mapping(address=>bool) private whitelist;

    function addToWhitelist (address _address) external {
        require(_address != address(0), "Invalid address");
        require(!whitelist[_address]);
        whitelist[_address] = true;
    }
    function removeFromWhitelist(address _address) external onlyWhitelisted{
        require(_address != address(0),  "Invalid address.");
        require(whitelist[_address] == true, "Address not on the whitelist");

        whitelist[_address] = false;
    }

    //function to check if an address is  whitelisted or not
    function isWhitelisted (address _address) external view returns (bool _isWhitelisted) {
        return whitelist[_address];
    }

    //modifier to restruct functions to whitelisted addresses
    modifier onlyWhitelisted () {
        require (whitelist[msg.sender], "You are not whitelisted.");
        _;
    }
}