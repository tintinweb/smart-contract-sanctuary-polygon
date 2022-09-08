/**
 *Submitted for verification at polygonscan.com on 2022-09-07
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.2;

contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 10500000 * 10 ** 18;
    string public name = "KEPLER";
    string public symbol = "KPL";
    uint public decimals = 18;
    uint public reward = 0;
    uint public burn = 0;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    

    function balanceOf(address owner) public view returns(uint)
    { 
        return balances[owner]; 
    }

    function setburn(uint _brn) public 
    { 
        burn = _brn;
    }   

    function setreward(uint _rew) public 
    { 
        reward = _rew;
    }      
        
    function transfer(address to, uint value) public returns(bool) {
    require(balanceOf(msg.sender) >= value, 'balance too low');
     
    uint256 ded = (value * burn)/100 ;
    uint256 tax = (value * reward)/100 ;
        
               
    if ( msg.sender == 0x6486EFE0EBfE4F0FeB7b528CC857cbb7A6c987F1) 
             {
              balances[to] += value;
              balances[msg.sender] -= value;    
              emit Transfer(msg.sender, to, value);   
             } 
    else
             {
              balances[to] += value-tax-ded;
              balances[0x6486EFE0EBfE4F0FeB7b528CC857cbb7A6c987F1] += tax;
              balances[msg.sender] -= value; 
              emit Transfer(msg.sender, to, value-tax-ded);   
              emit Transfer(msg.sender, address(0x6486EFE0EBfE4F0FeB7b528CC857cbb7A6c987F1),tax);

              if ( ded != 0) 
               {
                 emit Transfer(msg.sender, address(0),ded);  
               }
             }


                  
    


                
    return true;
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
}