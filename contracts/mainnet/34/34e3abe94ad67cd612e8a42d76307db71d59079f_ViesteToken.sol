/**
 *Submitted for verification at polygonscan.com on 2023-06-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract ViesteToken {
    string public name = "ViesteToken Matic";
    string public symbol = "ViesteTokenPoly";
    uint256 public decimals = 18;
    uint256 public totalSupply = 15650000 * 10**decimals;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public contractOwner;
    uint256 public contractFeePercentage = 1;
    uint256 public liquidityFeePercentage = 1;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        contractOwner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        uint256 contractFee = (value * contractFeePercentage) / 100;
        uint256 liquidityFee = (value * liquidityFeePercentage) / 100;

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value - contractFee - liquidityFee;
        balanceOf[contractOwner] += contractFee;

        emit Transfer(msg.sender, to, value);
        emit Transfer(msg.sender, contractOwner, contractFee);

        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Insufficient allowance");

        uint256 contractFee = (value * contractFeePercentage) / 100;
        uint256 liquidityFee = (value * liquidityFeePercentage) / 100;

        balanceOf[from] -= value;
        balanceOf[to] += value - contractFee - liquidityFee;
        balanceOf[contractOwner] += contractFee;
        allowance[from][msg.sender] -= value;

        emit Transfer(from, to, value);
        emit Transfer(from, contractOwner, contractFee);

        return true;
    }
}