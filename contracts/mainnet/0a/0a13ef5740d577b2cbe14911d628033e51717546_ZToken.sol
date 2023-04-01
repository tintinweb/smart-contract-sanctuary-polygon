/**
 *Submitted for verification at polygonscan.com on 2023-03-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract ZToken {
    string public symbol = "ZTKN";
    uint public totalSupply = 1000000;

    mapping(address => uint) public balanceOf;

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address payable to, uint amount) external payable {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        require(msg.value == amount / 20, "Incorrect ether amount");

        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;

        uint fee = amount / 10;
        balanceOf[address(this)] += fee;
        balanceOf[msg.sender] -= fee;
        payable(address(msg.sender)).transfer((9 * fee) / 10);
        payable(address(this)).transfer(fee / 10);

        payable(address(this)).transfer(msg.value);
        payable(address(msg.sender)).transfer(msg.value);
    }
}