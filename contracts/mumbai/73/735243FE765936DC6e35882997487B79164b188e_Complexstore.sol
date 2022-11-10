/**
 *Submitted for verification at polygonscan.com on 2022-11-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
contract Complexstore{
	uint256 public keyCount = 0;
	mapping(uint256=>string) public keys;
	mapping(string=>uint256) public indexForKeys;
	mapping(uint256=>string) public values;
	function putData(string calldata key, string calldata value) external {
		if(indexForKeys[key] == 0) {
			keyCount++;
			keys[keyCount] = key;
			indexForKeys[key] = keyCount;
		}
		values[indexForKeys[key]] = value;
	}
}