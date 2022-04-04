//SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract Bool {
    bool public boolValue;

    function setBool(bool v) external {
        boolValue = v;
    }
}