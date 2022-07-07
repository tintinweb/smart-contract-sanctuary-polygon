// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract BoxTest {
    uint256 private value;

    // Emitted when the stored value is changed.
    event ValueChanged(uint256 newValue);
    
    //Store a new value in the contract
    function store(uint256 newValue) public {
        value = newValue;
        emit ValueChanged(newValue);
    }

    // Reads the last stored value.
    function retrieve() public view returns (uint256) {
        return value;
    }
}