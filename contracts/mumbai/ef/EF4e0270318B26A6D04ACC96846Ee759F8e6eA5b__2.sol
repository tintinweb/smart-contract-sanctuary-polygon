/**
 *Submitted for verification at polygonscan.com on 2022-09-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 

contract _1
{

    constructor (uint _a) {
        a = _a;
    }
    uint public a ;
    
    function test2 () internal pure returns(uint)
    {
        return 6;
    }
}
// File: contract_2.sol



contract _2 is _1
{
    constructor (uint a_)  _1 (a_){}
    
    function sum (uint b) public view returns(uint)
    {
        return b + a;
    }

    function DevelopTest (uint a) external virtual view returns(uint)
    {

    }
}