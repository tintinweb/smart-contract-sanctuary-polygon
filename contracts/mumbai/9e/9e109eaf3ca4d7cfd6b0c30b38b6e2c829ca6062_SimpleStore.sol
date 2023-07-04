// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract SimpleStore {
    uint256 public x = 100e18;

    function set(uint256 _x) public {
        x = _x;
    }

    function get() public view returns (uint256) {
        return x;
    }
}