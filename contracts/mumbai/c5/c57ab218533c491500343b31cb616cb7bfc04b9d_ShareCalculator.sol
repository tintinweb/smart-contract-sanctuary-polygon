/**
 *Submitted for verification at polygonscan.com on 2023-03-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ShareCalculator {
    uint8 constant public decimals = 6; 
    uint256 constant public UNIT =  (10 ** decimals);
    uint256 constant public times = 10000000000;
    uint256 public singlePrice = 2 * UNIT;
    uint256 public fib0 = 0;
    uint256 public fib1 = 100000 * UNIT;
    uint256 public round = 1;
    uint256 public accDollar;
    uint256 public accShare;

    
    function calculateShare(
        uint64 mainType,
        uint64 subType,
        address player,
        uint256 dollar
    ) external returns (uint256) {
        uint256 fib2 = fib0 + fib1;
        uint256 share = times * singlePrice / fib2;
        // share -= (share % UNIT);
        accShare += share;
        accDollar += dollar;
        if (accDollar >= fib2) {
            fib0 = fib1;
            fib1 = fib2;
            round += 1;
        }
        return share;
    }
}