/**
 *Submitted for verification at polygonscan.com on 2023-05-21
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;


contract Errorhandling {
   address public owner;
   uint public balance;
   constructor() {
         owner = msg.sender;
   }
   
   function setDestructContract(address payable _address) public{
      require(msg.sender == owner, "Only contract owner can run this function");
      selfdestruct(_address);
   }
   
   function ReciveEther() public payable returns(uint){
      balance = address(this).balance;
      return balance;
   }
   
   
}