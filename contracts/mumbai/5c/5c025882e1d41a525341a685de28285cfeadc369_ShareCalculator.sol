/**
 *Submitted for verification at polygonscan.com on 2023-03-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ShareCalculator {
    uint8 constant public decimals = 6; // 无需调整，用更换合约的方式进行调整
    uint256 constant public UNIT =  (10 ** decimals);
    uint256 constant public times = 10000000000;
    uint256 public singlePrice = 2 * UNIT;
    uint256 public fib0 = 0;
    uint256 public fib1 = 100000 * UNIT;
    uint256 public round = 1;
    uint256 public accDollar;

    // 轮次计算（达到）：[ 1轮10万 | 2轮20万 | 3轮30万 | 4轮50万 ｜ 5轮80万 ｜ 6轮130万 ]
    // 100亿倍 * (单价) / 当前轮次最大目标值
    function calculateShare(
        uint64 mainType,
        uint64 subType,
        address player,
        uint256 dollar
    ) external returns (uint256) {
        uint256 fib2 = fib0 + fib1;
        uint256 share = times * singlePrice / fib2;
        share -= (share % UNIT);
        accDollar += dollar;
        if (accDollar >= fib2) {
            fib0 = fib1;
            fib1 = fib2;
            round += 1;
        }
        return share;
    }
}