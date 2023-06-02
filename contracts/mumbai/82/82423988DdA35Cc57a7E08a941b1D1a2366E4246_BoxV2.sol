// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract BoxV2 {
    uint256 private value;

    // Emitted when the stored value is changed
    event ValueChanged(uint256 newValue);

    // Stores a new value in the contract
    function store(uint256 newValue) public {
        value = newValue;
        emit ValueChanged(newValue);
    }

    // Reads the last record value
    function retrieve() public view returns (uint256) {
        return value;
    }

    // Increment the stored value by 1
    function increment() public {
        value = value + 1;
        emit ValueChanged(value);
    }
}