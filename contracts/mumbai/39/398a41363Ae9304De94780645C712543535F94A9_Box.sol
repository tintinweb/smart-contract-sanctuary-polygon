// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;



contract Box {
    uint256 private _value;

    event ValueChanged(uint256 value);



    // stores a new value
    function store(uint256 value) public {
        _value = value;
        emit ValueChanged(value);
    }

    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return _value;
    }
}