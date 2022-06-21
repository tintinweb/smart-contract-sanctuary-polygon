/**
 *Submitted for verification at polygonscan.com on 2022-06-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom( address sender,address recipient,uint amount ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Piramid is IERC20 {

    string public name = "Piramid Token";
    string public symbol = "PIRAMID";
    uint8 public decimals = 18;
    address public Owner;
    uint public totalSupply = 1000000*10**decimals;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    constructor() {
        Owner = msg.sender;
        balanceOf[Owner] = totalSupply;
        emit Transfer(address(0), Owner, totalSupply);
    }

    modifier onlyOwner() {
        require(msg.sender == Owner, "Not owner");
        _;
    }

    function changeOwner(address newOwner) public onlyOwner{
        Owner = newOwner;
    }

    function transfer(address recipient, uint amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function burn(uint amount) external returns(bool){
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }

    function mint(uint amount) public onlyOwner{
        totalSupply = totalSupply+amount;
        balanceOf[msg.sender] += amount;
        emit Transfer(address(0), Owner, amount);
    }
}