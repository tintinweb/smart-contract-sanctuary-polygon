/**
 *Submitted for verification at polygonscan.com on 2023-04-30
*/

// File: ../../../../../../Users/machd/Documents/codes/solidity-lessons/contracts-playground/src/DemoDeploy.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

contract DemoDeploy {
    function arithmetic(uint a, uint b)
        public
        pure
        returns (uint sum, uint product)
    {
        return (a + b, a * b);
    }
}