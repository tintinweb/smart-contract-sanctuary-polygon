/**
 *Submitted for verification at polygonscan.com on 2023-02-06
*/

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract percent{
  
    
    address  public creator;
    uint public tax;
   
    constructor(){
        creator=msg.sender;
    }
    mapping(address => uint) public balances;
    mapping(address=>address)public myreffr;
    function deposit(uint _amount,address payable _reffer)public{
      balances[msg.sender]+=_amount;
      myreffr[msg.sender]=_reffer;
      tax=_amount*50/100;
    //   balances[_reffer]+=tax;
      payable(creator).transfer(tax);
      
    }
}