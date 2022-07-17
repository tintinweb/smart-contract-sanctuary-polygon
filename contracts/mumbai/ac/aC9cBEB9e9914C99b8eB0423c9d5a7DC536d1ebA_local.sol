/**
 *Submitted for verification at polygonscan.com on 2022-07-16
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract local
{
    //by default variable visibilty is private
    // if we use public in a state variable then we dont need a getter
  uint public age =10;

  /*
  function getter() public view returns(uint)
  {
      return age;
  }
*/

//When you call a setter function it creates a transaction that needs to be mined and costs gas beacause it changes the blockchain
//setter function potentially change the values of the state variables and every change in the value will cost gas
//getter funtions cost no gas
  function setter(uint newage) public 
  {
      age=newage;
  }

}