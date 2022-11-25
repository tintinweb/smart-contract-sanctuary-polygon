/**
 *Submitted for verification at polygonscan.com on 2022-11-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract DGNicknames {

	address public owner;

	mapping(address => string) public nicknames;

	constructor() {
		owner = msg.sender;
	}

	function setNickname(string memory name) external {
		nicknames[msg.sender] = name;
	}

	function adminSetNickname(address addr, string memory name) external {
		require(msg.sender == owner);
		nicknames[addr] = name;
	}
}