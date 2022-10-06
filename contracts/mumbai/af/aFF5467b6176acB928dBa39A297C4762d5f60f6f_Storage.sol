/**
 *Submitted for verification at polygonscan.com on 2022-10-06
*/

// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.7;     //version

contract Storage {
    uint public myvalue = 0;
    function store(uint _myvalue) public {
        myvalue = _myvalue;
    }
}