/**
 *Submitted for verification at polygonscan.com on 2023-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BasicContract {
    address owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    function deposit() payable public {
        
    }
    
    function withdraw(uint amount) public {
        require(msg.sender == owner, "Only the owner can withdraw funds");
        require(amount <= address(this).balance, "Insufficient balance");
        
        payable(msg.sender).transfer(amount);
    }
}