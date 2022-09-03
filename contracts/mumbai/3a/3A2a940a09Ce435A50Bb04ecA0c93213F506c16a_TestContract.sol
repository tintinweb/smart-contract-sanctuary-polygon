// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

contract TestContract {
	uint public value;
	
	function setVal(uint val_) public {
		value = val_;
	}
}