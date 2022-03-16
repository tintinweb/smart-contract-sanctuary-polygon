/**
 *Submitted for verification at polygonscan.com on 2022-03-15
*/

pragma solidity >=0.7.0 <0.9.0;

contract Bank
{
    int balance;
    constructor() 
    {
        balance= 1;

    }

    function getBalance() view public returns(int)
    {
        return balance;
    }
  
  
    function withdraw(int amount) public
    {
         balance = balance - amount;
    }
    
    function deposit(int amount) public
    {
         balance = balance + amount;
    }




}