/**
 *Submitted for verification at polygonscan.com on 2023-02-10
*/

// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.17;
contract adder{
    int total;
    constructor() {
        total = 0;
    }   
    function getTotal() view public returns(int){
        return total;
    }   
    function addToTotal(int add) public returns (int){
        total=total+add;
        return total;
    }   
    function addToTotalConst(int add) public view returns (int){
        return total+add;
    }   
}