// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Credit{

    address public owner;
    mapping(address => uint) private Balance;
    mapping(address => bool) public initialized;

    modifier OnlyOwner(){
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    

    constructor(){
        Balance[msg.sender] = 100;
        owner = msg.sender;
    }

    function transaferCredit(address receiver, uint amount) public{
        require(Balance[msg.sender] >= amount, "Insufficient balance");
        Balance[msg.sender] -= amount;
        Balance[receiver] += amount;
    }

    function getBalance(address user) public view returns(uint){
        return Balance[user];
    }

    function init() public OnlyOwner{
        require(!initialized[msg.sender], "User already initialized");
        initialized[msg.sender] = true;
    }
    function mint (address receiver , uint amount) public OnlyOwner{
        Balance[receiver] += amount;
        Balance[msg.sender] -= amount;
        
    }
}