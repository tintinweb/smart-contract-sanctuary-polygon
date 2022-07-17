/**
 *Submitted for verification at polygonscan.com on 2022-07-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Events 
{
    event math(uint , uint , string);

    function sum (uint a, uint b) public 
    {
        uint sum_;
        sum_ = a + b;

        emit math (a , b , "+");

    }
}