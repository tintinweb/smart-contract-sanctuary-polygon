/**
 *Submitted for verification at polygonscan.com on 2023-03-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract real 
{


    uint public result;

    function _Sum (uint a , uint b) public 
    {
        result = a+b;
    }


    function div (uint a ,uint b) public pure returns(uint)
    {
        return a/b;
    }
}