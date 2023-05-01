/**
 *Submitted for verification at polygonscan.com on 2023-05-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract _21
{
    uint public result;

    function _sum (uint a, uint b) public 
    {
        result = a + b;
    }   

    function div (uint a , uint b) public pure returns (uint)
    {
        return a / b;
    }
}