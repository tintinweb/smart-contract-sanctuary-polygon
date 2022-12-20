// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Box{
    uint256 public value;

    //Emitted when the stored value changes
    // event ValueChanged(uint256 newValue);

    //Stores new value in the contract
    function store(uint256 newValue) public {
        value = newValue;
    }

}