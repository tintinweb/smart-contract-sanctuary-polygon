/**
 *Submitted for verification at polygonscan.com on 2023-03-09
*/

// Sources flattened with hardhat v2.12.3 https://hardhat.org

// File contracts/pools/lottery/ShareCalculator.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ShareCalculator {
    uint8 constant public decimals = 6; // 无需调整，用更换合约的方式进行调整
    uint256 constant public UNIT =  (10 ** decimals);
    uint256 constant public TIMES_UNIT = 10000000000 * UNIT;
    uint256 public fib0 = 0;
    uint256 public fib1 = 100000 * UNIT;
    uint256 public round = 1;
    uint256 public accDollar;
    uint256 public accShare;
    // uint256 public singlePrice = 2 * UNIT;
    // uint256 share = TIMES_UNIT * (dollar / singlePrice) * singlePrice / fib2;

    address platform;

    modifier onlyPlatform() {
        require(msg.sender == platform, "Not granted");
        _;
    }

    constructor(address _platform) {
        platform = _platform;
    }

    // 轮次计算（达到）：[ 1轮10万 | 2轮20万 | 3轮30万 | 4轮50万 ｜ 5轮80万 ｜ 6轮130万 ]
    // 100亿倍 * (单价) / 当前轮次最大目标值
    function calculateShare(
        uint64 mainType,
        uint64 subType,
        address player,
        uint256 dollar
    ) external onlyPlatform() returns (uint256) {
        mainType; subType; player; // to avoid warnings of compiler
        uint256 fib2 = fib0 + fib1;
        uint256 share = TIMES_UNIT * dollar / fib2;
        share -= (share % UNIT); // for example, 18333533333333333 => 18333533333000000
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

// https://mumbai.polygonscan.com/address/0xe6597696a7f9cfe6a83f0a31372b593d48e776ea#code