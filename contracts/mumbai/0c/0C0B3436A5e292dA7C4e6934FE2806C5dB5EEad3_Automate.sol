/**
 *Submitted for verification at polygonscan.com on 2022-07-12
*/

pragma solidity >=0.7.0 <0.9.0;
// SPDX-License-Identifier: MIT

contract Automate {


/** The function abc takes in 0 variables. It can only be called by functions outside of this contract. This function does the following : 
* transfers 2 of the native currency to the address that called this function
*/
	function abc() external {
		payable(msg.sender).transfer(2000000000000000000);
	}
}