/**
 *Submitted for verification at polygonscan.com on 2022-10-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

contract Keplercoins  {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    address public myAddress = 0x6486EFE0EBfE4F0FeB7b528CC857cbb7A6c987F1;
    address public rewardaddress = 0xF20038609657A61B9a1F5f7db84abfF91027BD38;
    address public burnaddress = 0x0000000000000000000000000000000000000000;
    uint public totalSupply = 0 * 10 ** 18;
    uint public CirculatingSupply = 0 * 10 ** 18;                  
    uint public MaxSupply = 21000000000 * 10 ** 18;
    string public name = "KEPLER";
    string public symbol = "KPL";
    uint public decimals = 18;
    uint public reward = 0;
    uint public burn = 0;
    
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = CirculatingSupply;
    }


     
    
    function IncreaseCirculatingSupply(uint value ) public  {

    if (myAddress==msg.sender)
    {  

    uint newsupply = value * 10 ** 18;
    uint newvalue = value * 10 ** 18;
    newsupply += CirculatingSupply ;    
    if ( newsupply <= MaxSupply) {
                                  balances[msg.sender] += newvalue;
                                  CirculatingSupply = newsupply;
                                  totalSupply = newsupply;
                                 }
    }                          
    }

    function balanceOf(address account) public view returns(uint) {
        return balances[account];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');

    uint ded = (value * burn)/1000 ;
    uint tax = (value * reward)/1000 ;
        
               
    if ( msg.sender == myAddress || msg.sender == rewardaddress) 
             {
              balances[to] += value;
              balances[msg.sender] -= value;    
              emit Transfer(msg.sender, to, value);   
             } 
    else
             {
              balances[to] += value-tax-ded;
              balances[rewardaddress] += tax;
              balances[msg.sender] -= value; 
              emit Transfer(msg.sender, to, value-tax-ded); 
              if ( tax != 0) 
               {  
                 emit Transfer(msg.sender, address(rewardaddress),tax);
               }
              if ( ded != 0) 
               {
                 emit Transfer(msg.sender, address(burnaddress),ded);  
               }
             }


        return true;
    }

    function transferFrom(address from, address to, uint value) public  returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }


    function setburn(uint _brn) public  
    { 
     if (myAddress==msg.sender) {   burn = _brn;}
    }   

    function setreward(uint _rew) public  
    { 
     if (myAddress==msg.sender) {  reward = _rew;}
    } 

    function setburnaddress(address _ba) public  
    { 
     if (myAddress==msg.sender) {  burnaddress = _ba;}
    } 

    function setrewardaddress(address _rw) public  
    { 
     if (myAddress==msg.sender) {  rewardaddress = _rw;}
    }
    function setmyAddress(address _ma) public  
    { 
     if (myAddress==msg.sender) {   myAddress = _ma;}
    }
    
}