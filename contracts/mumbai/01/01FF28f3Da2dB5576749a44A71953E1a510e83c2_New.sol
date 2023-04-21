/**
 *Submitted for verification at polygonscan.com on 2023-04-20
*/

// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.17 and less than 0.9.0
pragma solidity ^0.8.17;

contract New {
    uint public  a = 10;
    uint public  b = 10;
    
    function foo() external view returns(uint) {
        return a + b;
    }

    function bar() external payable returns(uint) {
        return a + b;
    }

}