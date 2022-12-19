// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

// ERC20 token contract
contract FrietorTestToken {
    // Public variables
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

     constructor() public {
        name = "Frietor";
        symbol = "FRT";
        decimals = 18;
        totalSupply = 170000000 * (10 ** uint256(decimals));
    }
}