/**
 *Submitted for verification at polygonscan.com on 2022-12-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract OkinamiStack {

    string public name;
    string public symbol;
    uint8 public decimals;
    address public owner;
    address private admin;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, address indexed to, uint256 value);
    event Reward(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor (string memory name_, string memory symbol_, uint8 decimals_) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        owner = msg.sender;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(msg.sender != address(0));
        require(to != address(0));
        require(value > 0);
        require(balanceOf[msg.sender] >= value);
        require(balanceOf[to] + value > balanceOf[to]);
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], value);
        balanceOf[to] = safeAdd(balanceOf[to], value); 
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(from != address(0));
        require(to != address(0));
        require(value > 0);
        require(balanceOf[from] >= value);
        require(balanceOf[to] + value > balanceOf[to]);
        require(allowance[from][msg.sender] >= value);
        balanceOf[from] = safeSub(balanceOf[from], value);
        balanceOf[to] = safeAdd(balanceOf[to], value);
        allowance[from][msg.sender] = safeSub(allowance[from][msg.sender], value);
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        require(msg.sender != address(0));
        require(spender != address(0));
        require(value > 0);
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function burn(uint256 value) public {
        require(balanceOf[msg.sender] >= value);
        require(value > 0);
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], value);
        totalSupply = safeSub(totalSupply, value);
        emit Burn(msg.sender, address(0), value);
    }

    function burnFrom(address from, uint256 value) public {
        require(owner == msg.sender);
        require(balanceOf[from] >= value);
        require(value > 0);
        balanceOf[from] = safeSub(balanceOf[from], value);
        totalSupply = safeSub(totalSupply, value);
        emit Burn(from, address(0), value);
    }

    function reward(address to, uint256 value) public {
        require(msg.sender == admin);
        balanceOf[to] = safeAdd(balanceOf[to], value);
        totalSupply = safeAdd(totalSupply, value);
        emit Reward(address(0), to, value);
    }

    function transferAdmin(address newAdmin) public virtual {
        require(owner == msg.sender);
        admin = newAdmin;
    }

    function renounceOwnership() public virtual {
        require(owner == msg.sender);
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
        admin = address(0);
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c>=a && c>=b);
        return c;
    }
    
}