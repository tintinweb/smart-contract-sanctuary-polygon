/**
 *Submitted for verification at polygonscan.com on 2022-08-25
*/

// SPDX-License-Identifier: MIT
// Specifies that the source code is for a version
// of Solidity greater than 0.8.16
pragma solidity ^0.8.16;

// A contract is a collection of functions and data (its state)
// that resides at a specific address on the Ethereum blockchain.
contract Form1 {

    function add(int a, int b) public pure returns (int)
    {
        int Sum = a + b ;
         
        // Sum of two variables
        return Sum;
    }

}