/**
 *Submitted for verification at polygonscan.com on 2023-05-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract JDGTLToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed to, uint256 value);

    uint256 public pricePerToken;

    constructor() {
        name = "JDGTL";
        symbol = "JDGTL";
        decimals = 18;
        totalSupply = 100000000 * 10**uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        pricePerToken = 1; // 1 Matic for 1 JDGTL token
    }

    function mint(address to, uint256 value) external {
        require(value > 0, "Invalid amount");

        totalSupply += value;
        balanceOf[to] += value;

        emit Transfer(address(0), to, value);
        emit Mint(to, value);
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(to != address(0), "Invalid recipient");
        require(value <= balanceOf[msg.sender], "Insufficient balance");

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function tokenURI() external pure returns (string memory) {
        return "https://bafybeiagt7oblf6vp5au36q4ejszjsx4rdkuh6jihe64ezut73ubagheka.ipfs.w3s.link/";
    }
}