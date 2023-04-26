/**
 *Submitted for verification at polygonscan.com on 2023-04-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title Stores cids on array
 * @notice Cid must be passed as hex value: 0x...
 */
contract SurveysStorageArray {
    uint256[] private cids;
    function addCid(uint256 value) public {
        cids.push(value);
    }
    function getCids() public view returns (uint256[] memory) {
        return cids;
    }
    function getCid(uint16 index) public view returns (uint256) {
        require(index < cids.length, "Index out of range");
        return cids[index];
    }
    function getCidsCount() public view returns (uint256) {
        return cids.length;
    }
}