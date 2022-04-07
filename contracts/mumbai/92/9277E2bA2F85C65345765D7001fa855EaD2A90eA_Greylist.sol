//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Greylist {
	// address of minter -> timestamp of greylist end
	mapping(address => uint256) public greylistedAddresses;

	function addToGreylist(address _addressToGreylist) public {
		// greylist address for 2 seconds
		greylistedAddresses[_addressToGreylist] = block.timestamp + 2 seconds;
	}

	function isGreylisted(address _addressToCheck) public view returns (bool) {
		if (greylistedAddresses[_addressToCheck] > block.timestamp) {
			return true;
		}
		return false;
	}
}