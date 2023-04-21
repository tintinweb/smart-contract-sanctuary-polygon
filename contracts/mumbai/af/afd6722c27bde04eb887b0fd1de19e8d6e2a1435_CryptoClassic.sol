/**
 *Submitted for verification at polygonscan.com on 2023-04-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract CryptoClassic {
    string public name = "CryptoClassic";
    string public symbol = "CRC";
    uint8 public decimals = 9;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Mint(address indexed to, uint256 value);

    uint256 public tokenPrice; // Token price
    address public owner; // Token owner

    // %5 commission addresses
    address public address1 = 0x12389e72AA8560111DC2FBBD2DEdE39Ace4b1290;
    address public address2 = 0xEED2A1936838accf987D9F266aEacaedD88d5388;

    mapping(address => bool) public whitelist; // White list

    constructor(uint256 _tokenPrice) {
        owner = msg.sender;
        totalSupply = 100000000 * 10**uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        tokenPrice = _tokenPrice;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    // Function to whitelist wallets exempt from trade tax
    function addToWhitelist(address[] memory addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = true;
        }
    }

    // Function to whitelist wallets exempt from trade tax
    function removeFromWhitelist(address[] memory addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = false;
        }
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        uint256 commission = value / 20; // %5 commission
        uint256 transferAmount = value - commission;
        balanceOf[msg.sender] -= value;
        balanceOf[to] += transferAmount;
        if (whitelist[msg.sender]) {
            // No commission from trade tax exempt wallet
            balanceOf[address1] += 0;
            balanceOf[address2] += 0;
        } else {
            balanceOf[address1] += commission / 2;
            balanceOf[address2] += commission / 2;
        }
        emit Transfer(msg.sender, to, transferAmount);
        emit Transfer(msg.sender, address1, commission / 2);
        emit Transfer(msg.sender, address2, commission / 2);
        return true;
    }

    // Other functions...
}