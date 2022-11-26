// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract Payable {
	uint public x;

	function increment() public {
		x ++;
	}

	function double() public payable {
		x *= 2;
	}

	function reset() public payable {
		require(msg.value == x * 10 ** (18 - 2), "");
		x = 0;
	}
}