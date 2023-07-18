/**
 *Submitted for verification at polygonscan.com on 2023-07-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title ChainDatabase
 * @dev This contract is simply used to store data for prototype apps
 */
contract ChainDatabase {
    mapping(uint256 => string[]) public data;

    constructor() {}

    function addDataElement(uint256 key, string memory value) public {
        data[key].push(value);
    }

    function getDataElement(
        uint256 key,
        uint256 index
    ) public view returns (string memory) {
        return data[key][index];
    }

    function getDataArrayCount(uint256 key) public view returns (uint256) {
        return data[key].length;
    }

    function getDataArray(uint256 key) public view returns (string[] memory) {
        return data[key];
    }
}