/**
 *Submitted for verification at polygonscan.com on 2022-07-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Events 
{
    event mathical (uint number_1 ,uint number_2, uint result, string math); // "+" "/"

    function sum (uint a, uint b) public 
    {
        uint sum_ = a + b;

        emit mathical (a , b , sum_ , "+");
    }
}