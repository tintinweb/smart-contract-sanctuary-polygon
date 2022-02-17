/**
 *Submitted for verification at polygonscan.com on 2022-02-17
*/

// File: HelloWorld.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract EtherWallet {
    address payable public owner;


    constructor() {
        owner = payable(msg.sender);
    }

    receive() external payable {}

    function withdraw(uint _amount) external {
        require(msg.sender == owner, "not owner");
        payable(msg.sender).transfer(_amount);  
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }

    
}