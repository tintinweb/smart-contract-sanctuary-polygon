/**
 *Submitted for verification at polygonscan.com on 2022-04-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract RandomNumbers{
    function createRandom(uint number) public view returns(uint){
        return uint(blockhash(block.number-1)) % number;
    }
}