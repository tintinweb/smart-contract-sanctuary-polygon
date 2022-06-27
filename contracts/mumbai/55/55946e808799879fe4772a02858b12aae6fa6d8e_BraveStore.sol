/**
 *Submitted for verification at polygonscan.com on 2022-06-26
*/

// Sources flattened with hardhat v2.9.9 https://hardhat.org

// File contracts/BraveStore.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

contract BraveStore {
	bool private initialized;
	address private owner;

	string public name;

	function initialize() public {
		require(!initialized);
		initialized = true;
		owner = msg.sender;
	}

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}

	function setName(string memory _name) public onlyOwner {
		name = _name;
	}
}