/**
 *Submitted for verification at polygonscan.com on 2023-05-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract CatMemeToken {
    string public name = "Cat Meme";
    string public symbol = "CAT";
    uint256 public totalSupply = 99000000000 * 10 ** 18; // 99 billion tokens
    uint8 public decimals = 18;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    address private liquidityWallet;
    address private marketingWallet;
    uint256 private maxWalletPercent = 5; // 5% maximum wallet percentage

    uint256 private liquidityTax = 1; // 1% liquidity tax
    uint256 private marketingTax = 2; // 2% marketing tax
    uint256 private maxTax = 3; // 3% max tax

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(amount <= balances[msg.sender], "Insufficient balance");
        require(amount <= getMaxWalletTokens(), "Exceeds maximum wallet token limit");
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(amount <= balances[sender], "Insufficient balance");
        require(amount <= allowances[sender][msg.sender], "Insufficient allowance");
        require(amount <= getMaxWalletTokens(), "Exceeds maximum wallet token limit");
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, allowances[sender][msg.sender] - amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setLiquidityTax(uint256 taxPercent) public {
        require(taxPercent <= maxTax, "Invalid tax percentage");
        liquidityTax = taxPercent;
    }

    function setMarketingTax(uint256 taxPercent) public {
        require(taxPercent <= maxTax, "Invalid tax percentage");
        marketingTax = taxPercent;
    }

    function setLiquidityWallet(address wallet) public {
        liquidityWallet = wallet;
    }

    function setMarketingWallet(address wallet) public {
        marketingWallet = wallet;
    }

    function setMaxWalletPercent(uint256 percent) public {
        require(percent <= 100, "Invalid percentage");
        maxWalletPercent = percent;
    }

    function transferOwnership(address newOwner) public {
        require(newOwner != address(0), "Invalid address");
        balances[newOwner] = balances[msg.sender];
        balances[msg.sender] = 0;
        emit Transfer(msg.sender, newOwner, balances[newOwner]);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "Invalid sender address");
        require(recipient != address(0), "Invalid recipient address");
        require(amount > 0, "Invalid amount");

        uint256 taxAmount = calculateTax(amount);
        uint256 transferAmount = amount - taxAmount;

        balances[sender] -= amount;
        balances[recipient] += transferAmount;

        if (taxAmount > 0) {
            balances[liquidityWallet] += taxAmount / 2;
            balances[marketingWallet] += taxAmount - taxAmount / 2;
        }

        emit Transfer(sender, recipient, transferAmount);
        emit Transfer(sender, liquidityWallet, taxAmount / 2);
        emit Transfer(sender, marketingWallet, taxAmount - taxAmount / 2);
    }

    function calculateTax(uint256 amount) private view returns (uint256) {
        uint256 taxAmount = 0;
        if (liquidityTax > 0) {
            taxAmount += (amount * liquidityTax) / 100;
        }
        if (marketingTax > 0) {
            taxAmount += (amount * marketingTax) / 100;
        }
        return taxAmount;
    }

    function getMaxWalletTokens() private view returns (uint256) {
        return (totalSupply * maxWalletPercent) / 100;
    }
}