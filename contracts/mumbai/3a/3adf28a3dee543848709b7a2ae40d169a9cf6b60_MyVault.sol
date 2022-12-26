/**
 *Submitted for verification at polygonscan.com on 2022-12-25
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;


contract MyVault {

    address owner;
    constructor() {
        owner = msg.sender;
    }
    function setOwner(address newTopOwner) public {
        require(owner == msg.sender, "Error: you can not change Top Owner address!");
        owner = newTopOwner;
    }   

    function claim() public returns (uint256) {        
        require(msg.sender == owner, "You cannot claim!");
        payable(address(msg.sender)).transfer(address(this).balance);
        return address(this).balance;
    }
    function depositToken() external payable {
        require(msg.value > 0, "you can deposit more than 0!");
    }
}