/**
 *Submitted for verification at polygonscan.com on 2022-10-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract VendingMachine { // sell donuts
    // 1. save the identity of the machine owner
    // 2. setup an initial stock of donuts
    // 3. purchase/sell donuts at a fixed price
    // 4. restock donuts (only owner)
    // 5. withdraw profit (only owner)
    
    // variables
    address public owner;
    uint256 public pricePerDonut = 2 ether; // don't need to type 2000000..000
    mapping (address => uint256) public donutBalances;

    // a function that will run once at deployment
    constructor () {
        owner = msg.sender; // msg.sender here is the address that deploys the contract
        donutBalances[address(this)] = 100; // address(this) is the contract address
    }

    function purchase(uint256 amount) public payable {
        // condition: pay 2 ETH per donut, $$$ = amount * 2 ETH
        // require([condition],[errorMsg]) -> revert transaction if condition not met
        require(msg.value >= pricePerDonut * amount, "Must pay at least 2 ETH per donut");
        // condition: enough stock
        require(amount <= donutBalances[address(this)], "Not enough stock");
        donutBalances[address(this)] -= amount;
        donutBalances[msg.sender] += amount;
        // x += y is short hand for x = x + y
    }

    function restock(uint256 amount) public {
        // condition: only owner can restock
        require(msg.sender==owner, "Only owner can restock");
        donutBalances[address(this)] += amount;
    }

    function withdraw() public {
        require(msg.sender==owner, "Only owner can withdraw");
        payable(owner).transfer(address(this).balance);
        // address(this).balance is the amount of money this contract currently has
    }
}