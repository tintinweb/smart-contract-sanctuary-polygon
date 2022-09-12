/**
 *Submitted for verification at polygonscan.com on 2022-09-12
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.2;

contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    address public myAddress = 0x6486EFE0EBfE4F0FeB7b528CC857cbb7A6c987F1;
    address public rewardaddress = 0x6486EFE0EBfE4F0FeB7b528CC857cbb7A6c987F1;
    address public burnaddress = 0x0000000000000000000000000000000000000000;
    uint public totalSupply = 10500000 * 10 ** 18;
    string public name = "KEPLER NEW MOON";
    string public symbol = "KPL";
    uint public decimals = 18;
    uint public reward = 0;
    uint public burn = 0;
    
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');

    uint ded = (value * burn)/100 ;
    uint tax = (value * reward)/100 ;
        
               
    if ( msg.sender == myAddress) 
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
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
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
        burn = _brn;
    }   

    function setreward(uint _rew) public 
    { 
        reward = _rew;
    } 

    function setburnaddress(address _ba) public 
    { 
        burnaddress = _ba;
    } 

    function setrewardaddress(address _rw) public 
    { 
        rewardaddress = _rw;
    }
}