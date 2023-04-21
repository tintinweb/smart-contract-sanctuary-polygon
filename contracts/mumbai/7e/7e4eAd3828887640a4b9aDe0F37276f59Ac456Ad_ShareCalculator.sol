/**
 *Submitted for verification at polygonscan.com on 2023-04-21
*/

// Sources flattened with hardhat v2.13.0 https://hardhat.org

// File contracts/pools/lottery/ShareCalculator.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICalculateShare {
    function calculateShare(uint64 mainType, uint64 subType, address player, uint256 dollar)
        external
        returns (uint256);
}

contract ShareCalculator is ICalculateShare {
    uint8 public constant decimals = 6; // No adjustment required, adjusted with a replacement contract
    uint256 public constant UNIT = (10 ** decimals);
    uint256 public constant TIMES_UNIT = 10000000000 * UNIT;
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

    // Round calculation (reach target):
    // [ 1 => 100,000 | 2 => 200,000 | 3 => 300,000 | 4 => 500,000 ｜ 5 => 800,000 ｜ 6 => 1,300,000 ]
    // 10 billion times * (unit price) / maximum target value of current round
    function calculateShare(uint64 mainType, uint64 subType, address player, uint256 dollar)
        external
        onlyPlatform
        returns (uint256)
    {
        mainType;
        subType;
        player; // to avoid warnings of compiler
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