/**
 *Submitted for verification at polygonscan.com on 2023-07-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OneCommunityWhitelist {
    mapping(address => bool) private whitelist;

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], "Address not whitelisted");
        _;
    }

    function addToWhitelist(address _address) external {
        require(_address != address(0), "Invalid address");
        require(!whitelist[_address], "Address already whitelisted");

        whitelist[_address] = true;
    }

    function removeFromWhitelist(address _address) external {
        require(_address != address(0), "Invalid address");
        require(whitelist[_address], "Address not whitelisted");

        whitelist[_address] = false;
    }

    function isWhitelisted(address _address) external view returns (bool) {
        return whitelist[_address];
    }
}

// 0x71aD37f7E22Ee6c7cFC13a9b30a1Ad189B79bb49