/**
 *Submitted for verification at polygonscan.com on 2022-09-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract MINIMAL {
	
	// Mapping for wallet addresses that have previously minted
    mapping(address => bool) private whitelistMinters;

    mapping(address => bool) private whitelistAddresses;

	constructor()  {}
	
    function checkUserStatus(address _address) public view returns (bool) {
        return whitelistMinters[_address];
    }

    function checkUserWhitelistStatus(address _address) public view returns (bool) {
        return whitelistAddresses[_address];
    }

    function addToWhitelistSingle(address _address) external {
        whitelistAddresses[_address] = true;
    }
	
    function removeFromWhitelist(address _address) external {
		whitelistAddresses[_address] = false;
    }
	
	function mintKey() public payable {
        require(whitelistAddresses[msg.sender], "Not on whitelist");
        require(whitelistMinters[msg.sender] == false, "Already minted");
		
		whitelistMinters[msg.sender] = true;
		
    }
	
}