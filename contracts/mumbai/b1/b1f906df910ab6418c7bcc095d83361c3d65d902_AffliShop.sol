/**
 *Submitted for verification at polygonscan.com on 2022-11-12
*/

/**
 *Submitted for verification at polygonscan.com on 2022-11-12
*/

// SPDX-License-Identifier: MIT
 pragma solidity ^0.7.2;
 
 contract AffliShop {
     address public owner;
 
     constructor() public payable {
         owner = msg.sender;
     }
 
     modifier onlyOwner () {
       require(msg.sender == owner, "This can only be called by the contract owner!");
       _;
     }
 
     function deposit() payable public {
     }
 
 
     function WithdrawCompanyProfit() payable onlyOwner public {
         msg.sender.transfer(address(this).balance);
     }
 
 
     function getBalance() public view returns (uint256) {
         return address(this).balance;
     }

     function PayVendor(address payable _to) public payable onlyOwner {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent, bytes memory data) = _to.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }

    function PayAffiliate(address payable _to) public payable onlyOwner {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent, bytes memory data) = _to.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }
 }