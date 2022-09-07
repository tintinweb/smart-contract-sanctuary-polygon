// Solidity program to
// demonstrate how to
// write a smart contract
// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;	
// Defining a contract
contract Demo
{
	
	// Declaring state variables
	uint public var1;
	uint public var2;
	uint public sum;
	
	// Defining public function
	// that sets the value of
	// the state variable
	function set(uint x, uint y) public
	{
		var1 = x;
		var2=y;
		sum=var1+var2;
	}
		
	// Defining function to
	// print the sum of
	// state variables
	function get(
	) public view returns (uint) {
		return sum;
	}
}