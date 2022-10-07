/**
 *Submitted for verification at polygonscan.com on 2022-10-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Calculator {
  //addition
    function add(uint a, uint b) public pure returns (uint){
        return a+b;
    }
    //subtraction
    function subtract(uint a, uint b) public pure returns (uint){
        return a-b;
    }
     //multiplication
    function multiply(uint a, uint b) public pure returns (uint)
    {
        return a*b;
    }
     //division
    function division(uint a, uint b) public pure returns (uint){
        return a/b;

    }
    
}