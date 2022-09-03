/**
 *Submitted for verification at polygonscan.com on 2022-09-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract SITCONX {

    address public owner;
    mapping (address => uint256) public catsBalances;

    constructor() {
        owner = msg.sender;
        catsBalances[address(this)] = 10000;
    }

    function getCatsBalances() public view returns (uint256) {
        return catsBalances[address(this)];
    }

    function restock(uint256 amount) public {
        require(msg.sender == owner, "You are not the owner QAQ");
        catsBalances[address(this)] += amount;
    }

    function purchase(uint256 amount) public payable {
        require(msg.value >= amount * 0.01 ether, "You must pay greater than 0.01 MATIC.");
        require(catsBalances[address(this)] >= amount, "Meow, I'm out of stock QQ.");
        catsBalances[address(this)] -= amount;
        catsBalances[msg.sender] += amount;
    }
}