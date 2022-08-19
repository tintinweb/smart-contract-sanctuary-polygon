/**
 *Submitted for verification at polygonscan.com on 2022-08-18
*/

/**
 *Submitted for verification at polygonscan.com on 2022-08-05
*/

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;


contract gas1{

uint public a1;
uint public a2;
uint public a3;

    function test1() public{ //!!!more gas
    ++a1;
    ++a2;
    ++a3;
    }

    function test2() public{ //!!!more gas
    a2 = 1;
    a3 = 2;
    }

    function test3(uint input) public{
        a3 = input;
    }

}