/**
 *Submitted for verification at polygonscan.com on 2023-07-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract DTSCircle {

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed holder, uint256 value, uint256 remainder);
    event NewAdmin(address admin);

    string public name = "DTSCircle";
    string public symbol = "DTS";
    uint8 public decimals = 1;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    address public admin;

    constructor() {
        totalSupply = 3 * 10 ** 8;
        admin = msg.sender;
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function burn(uint256 amount) external returns (bool) {
        require(amount > 9, "Amount is too low!");
        uint256 remainder = amount % 10;
        uint256 clean = amount - remainder;
        balanceOf[msg.sender] -= clean;
        totalSupply -= clean;
        emit Burn(msg.sender, clean, remainder);
        return true;
    }

    function transferAdminship(address successor) external returns (bool) {
        require(msg.sender == admin, "Only admin!");
        admin = successor;
        emit NewAdmin(admin);
        return true;
    }
}