/**
 *Submitted for verification at polygonscan.com on 2023-01-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
contract Token {
    function say() payable public{
        require (msg.value == 1);
        
    }
}