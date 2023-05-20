// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract ProductImpl {
    bool private initialized;
    uint private value;

    modifier initializer() {
        require(!initialized, "This contract is initialized");
        _;
    }

    function initial() public initializer {
        initialized = true;
    }

    function add(uint _amount) public {
        value += _amount;
    }

    function getValue() public view returns (uint) {
        return value;
    }
}