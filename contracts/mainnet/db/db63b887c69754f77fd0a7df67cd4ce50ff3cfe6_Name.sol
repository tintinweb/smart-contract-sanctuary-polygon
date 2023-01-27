/**
 *Submitted for verification at polygonscan.com on 2023-01-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Name {
    bytes32 name;
    uint8 index;

    constructor() {
        name = "Anshu";
        index = 5;
    }

    function addA() public {
        name = bytes32(uint256(name) + 65);
        index++;
    }

    function getName() public view returns (string memory) {
    bytes memory nameBytes = abi.encodePacked(name);
    return string(nameBytes);
}
}