/**
 *Submitted for verification at polygonscan.com on 2023-05-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract MyToken {
    string public name = "testMatic";
    string public symbol = "TMT";
    uint256 public totalSupply = 10000000000000000000000000000; // 10 trillion with 18 decimals

    mapping(address => uint256) private balances;
    mapping(address => bool) private whitelist;

    address private owner;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    constructor() {
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    // Function to add addresses to the whitelist
    function addToWhitelist(address[] memory addresses, uint256[] memory tokenLimits) external onlyOwner {
        require(addresses.length == tokenLimits.length, "Mismatched array lengths");

        for (uint256 i = 0; i < addresses.length; i++) {
            address addr = addresses[i];
            uint256 limit = tokenLimits[i];

            whitelist[addr] = true;
            balances[addr] = limit;
        }
    }

    // Function to remove an address from the whitelist
    function removeFromWhitelist(address addr) external onlyOwner {
        whitelist[addr] = false;
        balances[addr] = 0;
    }

    // Function to check the token balance of an address
    function balanceOf(address addr) external view returns (uint256) {
        return balances[addr];
    }

    // Function to check if an address is whitelisted
    function isWhitelisted(address addr) external view returns (bool) {
        return whitelist[addr];
    }

    // Function to transfer tokens
    function transfer(address to, uint256 value) external returns (bool) {
        require(whitelist[msg.sender], "Sender is not whitelisted");
        require(value <= balances[msg.sender], "Insufficient balance");

        balances[msg.sender] -= value;
        balances[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    // Function to burn tokens
    function burn(uint256 value) external {
        require(whitelist[msg.sender], "Sender is not whitelisted");
        require(value <= balances[msg.sender], "Insufficient balance");

        balances[msg.sender] -= value;

        emit Burn(msg.sender, value);
    }
}