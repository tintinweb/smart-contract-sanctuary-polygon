/**
 *Submitted for verification at polygonscan.com on 2022-06-10
*/

// Sources flattened with hardhat v2.4.3 https://hardhat.org

// File contracts/token/BlackholeContract.sol

// SPDX-License-Identifier: MIT
pragma solidity >= 0.6.6;

contract BlackHoleContract {

    constructor() {}

    fallback() external payable {
        revert();
    }
}