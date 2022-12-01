// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Value {

    event ValueChanged(uint256 oldValue, uint256 newValue);

    uint256 public value;

    constructor(uint256 _value) {
        value = _value;
    }

    function updateValue(uint256 newValue) external {
        uint256 oldValue = value;
        value = newValue;
        emit ValueChanged(oldValue, value);
    }

}