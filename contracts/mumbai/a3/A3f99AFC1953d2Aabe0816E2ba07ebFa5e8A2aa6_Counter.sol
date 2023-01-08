/**
 *Submitted for verification at polygonscan.com on 2023-01-07
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Counter{
    uint public number;

    function sum() public{
        number = number + 1;
    }
}