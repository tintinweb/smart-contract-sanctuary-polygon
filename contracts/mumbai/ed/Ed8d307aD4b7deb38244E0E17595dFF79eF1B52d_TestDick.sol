//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestDick {
    string public dickSay;

    constructor(string memory dickSay_) {
        dickSay = dickSay_;
    }

    function say() external view returns (string memory) {
        return dickSay;
    }

    function setDickSay(string memory dickSay_) external {
        dickSay = dickSay_;
    }
}