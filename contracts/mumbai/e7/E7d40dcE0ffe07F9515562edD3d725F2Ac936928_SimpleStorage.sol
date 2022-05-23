// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

contract SimpleStorage {
    uint256 storedData;

    function set(uint256 y) public {
        storedData = y;
    }

    function get() public view returns (uint256) {
        return storedData;
    }
}