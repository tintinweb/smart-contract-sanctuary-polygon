/**
 *Submitted for verification at polygonscan.com on 2022-07-24
*/

// My First Smart Contract 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract HelloWorld {
    function get()public pure returns (string memory){
        return 'Hello Contracts';
    }
}