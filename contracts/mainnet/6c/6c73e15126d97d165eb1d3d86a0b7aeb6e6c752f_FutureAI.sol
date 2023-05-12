/**
 *Submitted for verification at polygonscan.com on 2023-05-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract FutureAI {
    string public name = "0xFutureAI Token";
    string public symbol = "0xFAI";
    uint256 public totalSupply = 100000000 * 10 ** 18; // 1 million tokens with 18 decimals
    uint8 public decimals = 18;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    uint256 public buyTax = 2; // 2% buy tax
    uint256 public sellTax = 2; // 2% sell tax
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event BuyTaxChanged(uint256 newTax);
    event SellTaxChanged(uint256 newTax);

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value, "Not enough balance");
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(balanceOf[from] >= value, "Not enough balance");
        require(allowance[from][msg.sender] >= value, "Not enough allowance");
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function setBuyTax(uint256 newTax) public {
        require(newTax <= 10, "Buy tax cannot be more than 10%");
        buyTax = newTax;
        emit BuyTaxChanged(newTax);
    }
    
    function setSellTax(uint256 newTax) public {
        require(newTax <= 10, "Sell tax cannot be more than 10%");
        sellTax = newTax;
        emit SellTaxChanged(newTax);
    }
    
    function _calculateTax(uint256 value, uint256 tax) private pure returns (uint256) {
        return value * tax / 100;
    }
    
    function buy() public payable {
        uint256 tokens = msg.value * (10 ** decimals) / (1 ether);
        require(tokens > 0, "Invalid amount");
        uint256 taxAmount = _calculateTax(tokens, buyTax);
        balanceOf[msg.sender] += tokens - taxAmount;
        balanceOf[address(this)] += taxAmount;
        emit Transfer(address(this), msg.sender, tokens - taxAmount);
    }
    
    function sell(uint256 tokens) public {
        require(balanceOf[msg.sender] >= tokens, "Not enough balance");
        uint256 taxAmount = _calculateTax(tokens, sellTax);
        balanceOf[msg.sender] -= tokens;
        balanceOf[address(this)] += taxAmount;
        payable(msg.sender).transfer((tokens - taxAmount) * (1 ether) / (10 ** decimals));
        emit Transfer(msg.sender, address(this), tokens);
    }
}