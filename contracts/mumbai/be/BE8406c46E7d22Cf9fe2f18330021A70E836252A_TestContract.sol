// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

contract TestContract {
	uint public value;
	
	event ValueChanged(uint oldValue, uint newValue);
	
	function setVal(uint newValue) public {
		emit ValueChanged(value, newValue);
		value = newValue;
	}
}