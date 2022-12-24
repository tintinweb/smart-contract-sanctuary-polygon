/**
 *Submitted for verification at polygonscan.com on 2022-12-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract ReturnLimitTest {
    uint256[] public array;

    function addToArray(uint256 count) external {
        for (uint256 i = 0; i < count; i++) {
            array.push(array.length);
        }
    }

    function getArray() external view returns (uint256[] memory) {
        return array;
    }
}