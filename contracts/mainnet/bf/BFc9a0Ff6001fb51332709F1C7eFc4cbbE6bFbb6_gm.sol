// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract gm {
    int private gms = 0;

    function getGms() public view returns (int) {
        return gms;
    }

    function getCode() public pure returns (string memory) {
        return "0x0EdD3EE977bDdf18eAa3548eC8544B78c78F40e5";
    }

    function write(string memory name) public returns (bytes32) {
        gms += 1;
        return keccak256(abi.encodePacked(name));
    }
}