/**
 *Submitted for verification at polygonscan.com on 2022-12-05
*/

pragma solidity >=0.7.0 <0.9.0;
// SPDX-License-Identifier: MIT


contract Escrow {

	function confirmDelivery1a(uint[] memory aa) public pure returns (uint) {
		aa[2] = 3;
		aa[25] = 4;
		aa[4] = 3;
		return aa[4];
	}

	function confirmBoolX(uint[] memory aa) public pure returns (uint) {
		return aa[5];
	}

}