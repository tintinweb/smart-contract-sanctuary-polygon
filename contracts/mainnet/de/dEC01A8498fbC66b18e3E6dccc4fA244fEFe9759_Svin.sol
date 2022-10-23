// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Svin{

    address public _owner;
    uint256 private allToken; 
    string public name;
    string public symbol;

    constructor(){
        _owner = msg.sender;
        name = "SVIN Token";
        symbol = "SVIN";
    }

    function totalSupply() public view returns(uint256){
        return allToken;
    }

    mapping(address => uint256) balance;

    function balanceOf(address account) public view returns(uint256){
        return balance[account];
    }

    function transfer(address recipient, uint256 amount) public {
        require(balance[msg.sender] >=  amount, "balanse djok");
        balance[msg.sender] -= amount;
        balance[recipient] += amount;
    }

    mapping(address => mapping(address => uint256)) _allowance;
    
    function allowance(address owner, address spender) public view returns(uint256){
        return _allowance[owner][spender];
    }

    function approve(address spender, uint256 amount) public {
        require(balance[msg.sender] >=  amount, "balanse djok");
        _allowance[msg.sender][spender] = amount;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public {
        require(_allowance[sender][msg.sender] >=  amount, "ini na hui wor");
        require(balance[sender] >=  amount, "balanse djok");
        balance[sender] -= amount;
        _allowance[sender][msg.sender] -= amount;
        balance[recipient] += amount;
    }

    function mint(address sender, uint256 amount) public {
        require(_owner ==  msg.sender, "ini na hui wor");
        balance[sender] +=  amount;
    }
}