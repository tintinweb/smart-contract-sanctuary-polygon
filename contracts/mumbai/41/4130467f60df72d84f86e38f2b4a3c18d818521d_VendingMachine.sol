/**
 *Submitted for verification at polygonscan.com on 2022-11-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract VendingMachine {
    address public owner;
    mapping(address => uint256) public donutBalance;

    modifier onlyOwner() {
        require(msg.sender==owner, "Only owner can perform this action");
        _; // function content goes here
    }

    constructor() {
        owner = msg.sender;
        donutBalance[address(this)] = 100; //address(this) = contract address
    }

    function restock(uint256 amount) public onlyOwner {
        donutBalance[address(this)] += amount;
    }

    function purchase(uint256 amount) public payable {
        require(amount <= donutBalance[address(this)], "Insufficient stock");
        require(msg.value == amount * 2 ether, "Incorrect payment");

        donutBalance[msg.sender] += amount;
        donutBalance[address(this)] -= amount;
    }

    function withdraw() public onlyOwner {
        // address payable to = payable(owner);
        payable(owner).transfer(address(this).balance);
    }
}