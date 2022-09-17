/**
 *Submitted for verification at polygonscan.com on 2022-09-17
*/

pragma solidity >=0.7.0 <0.9.0;
// SPDX-License-Identifier: MIT

contract PuzzlePay {

	function simplPay() public payable returns (uint256) {
        require (msg.value == 1000, "haha");
        return 5;
	}

	function simplPay1(uint input) public payable returns (uint256) {
        require (msg.value == input, "haha");
        return input;
	}

}