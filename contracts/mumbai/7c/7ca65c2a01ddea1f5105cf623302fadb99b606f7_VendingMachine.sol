/**
 *Submitted for verification at polygonscan.com on 2022-11-26
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract VendingMachine {
    address public owner; // store a owner for the contract
    mapping(address => uint256) public donutBalance; //addresses mapped to each address' balance

    modifier onlyOwner() { //modifier is a template to be applied to all functions in contract
        require(msg.sender == owner, "only owner can perform this action"); //checks if user is owner first
        _; //function content goes here
    }

    constructor() {
        owner = msg.sender;
         //whoever deployed contract is owner
        donutBalance[address(this)] = 100; //address(this) = this contract address, 100 to sell at the beginning, defining supply of collection

    }

    function restock(uint256 amount) public onlyOwner { //calls the onlyowner function, and then at the _; in modifier, it runs the content in current function
        // ... <- this part is run after onlyOwner is run first
        donutBalance[address(this)] += amount; //only the owner can restock by specified in amount

    }

    function purchase(uint256 amount) public payable { //allow everyone to buy. check balance, check buyer has enough $
        require(amount <= donutBalance[address(this)], "Insufficient stock");
        require(msg.value == amount * 2 ether, "Incorrect payment"); 

        donutBalance[msg.sender] += amount; //gives donut to their address
        donutBalance[address(this)] -= amount;
    } 

    function withdraw() public onlyOwner{ //to allow contract to take money out for owner
        // address payable to = payable(owner);
        payable(owner).transfer(address(this).balance); 
    } 
}