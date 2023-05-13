/**
 *Submitted for verification at polygonscan.com on 2023-05-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract TSGDToken
{
    string public name;
    string public symbol;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    event Mint(address indexed account, uint256 amount);
    event Burn(address indexed account, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);

    constructor()
    {
        name = 'TSGD Token';
        symbol = 'TSGD';
        totalSupply = 0;
    }

    function mint(address to, uint256 amount) public
    {
        balanceOf[to] += amount;
        totalSupply += amount;
        emit Mint(to, amount);
    }

    function burn(address to, uint256 amount) public
    {
        require(balanceOf[to] >= amount, 'Insufficient balance');
        balanceOf[to] -= amount;
        totalSupply -= amount;
        emit Burn(to, amount);
    }

    function transfer(address from, address to, uint256 amount) public
    {
        require(balanceOf[from] >= amount, 'Insufficient balance');
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
    }

    function getBalance(address to) public view returns (uint256)
    {
        return balanceOf[to];
    }
}