/**
 *Submitted for verification at polygonscan.com on 2022-11-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract EtherSender {
   address public owner;

    constructor() {
        owner = msg.sender;
    }  

    modifier withMoney() {
      require (address(this).balance > 0.01 ether, "not enough funds");
      _;
    } 

    function getBalance () public view returns(uint256) {
        return address(this). balance;
    } 

    function sendMoney() external payable {
      require(msg.value > 0.02 ether, "deposit must be greater than 0.02 eth");
    }

    function giveOneCent() external withMoney {
    	(bool success,) = msg.sender.call{value : 0.01 ether}("");
		  require(success, "failed");       
    }

    function giveHalf() external withMoney {
 	    (bool success,) = msg.sender.call{value : getBalance() / 2}("");
		  require(success, "failed");      
    }

    function giveTotal() external withMoney {
    	require(msg.sender == owner, "you are not the contract owner");
      (bool success,) = owner.call{value : getBalance()}("");
		  require(success, "failed");       
    }

}