/**
 *Submitted for verification at polygonscan.com on 2022-09-13
*/

// File: contracts/counter.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;
contract Counter{
    uint public count;
    //Function to get the current count 
    function get() public view returns (uint){
        return count;
    }

    //function to increment count by 10

    function inc() public {
        count +=10;
    }

    //Function to decrement count by 1
    function dec() public{
        //This function will fail when count =0 
        count -= 2;
    }
}