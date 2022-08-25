/**
 *Submitted for verification at polygonscan.com on 2022-08-24
*/

// SPDX-License-Identifier: UNLICENSED;

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
    function sum(int x, int y ) public pure returns( int){
        return x + y;
    }
    function subtract(int x, int y ) public pure returns( int){
        return x - y;
    }
    function multiply(int x, int y ) public pure returns( int){
        return x * y;
    }
    function divide(int x, int y ) public pure returns( int){
        return x / y;
    }
    function incrementCount() public {
        count +=1;
    }
    function resetCount () external onlyOwner {
        count = 0;
    }
}