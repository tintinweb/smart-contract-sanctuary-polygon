/**
 *Submitted for verification at polygonscan.com on 2022-02-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract CheckMath {

	uint public maxNumber0 = type(uint).max;
	uint public maxNumber8 = type(uint8).max;

	function add(uint num1, uint num2) external pure returns(uint) {
		return num1 + num2;
	}

	function substract(uint num1, uint num2) external pure returns(uint) {
		return num1 - num2;
	}

	function multiply(uint num1, uint num2) external pure returns(uint) {
		return num1 * num2;
	}

	function divide(uint num1, uint num2) external pure returns(uint) {
		return num1 / num2;
	}

}