/**
 *Submitted for verification at polygonscan.com on 2022-08-24
*/

// SPDX-License-Identifier: MIT;

pragma solidity ^0.8.7;

contract Calculator{
    address private owner;
    int public count;

    constructor(){
        count = 0;
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(owner == msg.sender);
        _;
    }
    function sum(int x, int y ) public returns( int){
        incrementCount();
        return x + y;
    }
    function subtract(int x, int y ) public returns( int){
        incrementCount();
        return x - y;
    }
    function multiply(int x, int y ) public returns( int){
        incrementCount();
        return x * y;
    }
    function divide(int x, int y ) public returns( int){
        incrementCount();
        return x / y;
    }
    function incrementCount() internal {
        count +=1;
    }
    function resetCount () external onlyOwner {
        count = 0;
    }
}