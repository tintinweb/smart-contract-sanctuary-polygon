/**
 *Submitted for verification at polygonscan.com on 2021-10-29
*/

// SPDX-License-Identifier: MIT


pragma solidity 0.8.9;

contract Books {
   mapping (address => mapping(uint256 => uint256)) private map; 
   uint256 private id;
   
   function setMap(uint256 number) public {
       id++;
       
       map[msg.sender][id] = number;
   }
   
   function getMap(uint256 number) public view returns (uint256) {
       uint256 saldo = map[msg.sender][number];
       return saldo;
   }
   
   function getMap2(address sender, uint256 number) public view returns (uint256) {
       
       return map[sender][number];
   }
}