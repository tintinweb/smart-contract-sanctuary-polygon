//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0 <0.9.0;


contract Token{
    string public name="Hardhat Token";
    string public symbol = "HHT";
    uint public totalSupply = 10000000000000000000000000;
    uint public decimal;

    address public owner;

    mapping(address=>uint) balances;

    constructor(){
        balances[msg.sender]=totalSupply;
        owner=msg.sender;
        decimal = 10;
    }

    function transfer(address to, uint amount) external{
        require(balances[msg.sender]>=amount,"Not enough tokens");
        balances[msg.sender]-=amount;
        balances[to]+=amount;
    }

    function balanceOf(address account) external view returns (uint256){
        return balances[account];
    }

}