/**
 *Submitted for verification at polygonscan.com on 2022-12-20
*/

// File: class.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract secondclass{
    string count = "";

    function my_function1() public view returns(string memory){
        return count;
    }

    function my_function2(string memory txt) public{
        count = string.concat(count, txt);
    }
}