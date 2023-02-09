/**
 *Submitted for verification at polygonscan.com on 2023-02-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
 
contract Box {
    uint256 private value;
 
    // Emitted when the stored value changes
    event ValueChanged(uint256 newValue);

    constructor(uint iv) {
        value = iv;
    }
 
    // Stores a new value in the contract
    function store(uint256 newValue) public {
        value = newValue;
        emit ValueChanged(newValue);
    }
 
    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return value;
    }
}