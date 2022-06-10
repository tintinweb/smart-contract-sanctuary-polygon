/**
 *Submitted for verification at polygonscan.com on 2022-06-10
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Storage {
   mapping(address => uint16) public store;

   event Set(address key);
   event Del(address key);

   function Add(address _address) public{
       store[_address]++;
       emit Set(_address);
   }

   function Remove(address _address) public {
       delete store[_address];
       emit Del(_address);
   }
}