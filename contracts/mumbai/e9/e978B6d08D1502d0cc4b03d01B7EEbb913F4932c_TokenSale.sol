/**
 *Submitted for verification at polygonscan.com on 2023-06-10
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract TokenSale {
    address public token;
    address public owner;
    uint public price;
    uint public tokensSold;

    event Sold(address buyer, uint amount);

    constructor(address _token, uint _price) {
        token = _token;
        owner = msg.sender;
        price = _price;
    }

    receive() external payable {
        buyTokens();
    }

    function buyTokens() public payable {
        uint tokenAmount = msg.value / price;
        require(tokenAmount > 0, "Insufficient payment");
        tokensSold += tokenAmount;
        emit Sold(msg.sender, tokenAmount);
        payable(owner).transfer(msg.value);
    }

    function withdrawFunds() public {
        require(msg.sender == owner, "Only the owner can withdraw funds");
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}