/**
 *Submitted for verification at polygonscan.com on 2022-05-26
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract WertTest {
    address public sender;
	constructor() {
	}

	function transfer(address recepiment ) public payable {
        sender = msg.sender;
        payable(recepiment).transfer(msg.value);
    }

}