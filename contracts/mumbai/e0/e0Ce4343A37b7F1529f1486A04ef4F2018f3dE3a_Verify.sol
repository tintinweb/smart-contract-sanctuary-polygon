// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Verify {
	string private constant GREETING = "Hello!";

	function sayHello(bool _do) public pure returns(string memory) {
		if (_do) {
			return GREETING;
		}
		return "";
	}
}