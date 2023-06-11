/**
 *Submitted for verification at polygonscan.com on 2023-06-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;


contract testBBS{
    uint number;

    function setNumber(uint n) public{
        number=n;
    }

    function getNumber() public view returns (uint){
        return number;
    }
}