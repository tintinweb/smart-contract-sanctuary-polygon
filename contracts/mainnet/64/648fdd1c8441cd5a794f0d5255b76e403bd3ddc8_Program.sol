/**
 *Submitted for verification at polygonscan.com on 2022-08-27
*/

// SPDX-License-Identifier: unlicenced

pragma solidity ^0.8.13;

interface ISnowV1Program {
    function name() external view returns (string memory);

    function run(uint256[64] memory canvas, uint8 lastUpdatedIndex)
        external
        returns (uint8 index, uint256 value);
}

contract Program is ISnowV1Program {
    function run(uint256[64] memory canvas, uint8 lastUpdatedIndex) external pure returns (uint8, uint256) {
        return (0, 0);
    }

    function name() external pure returns (string memory) {
        return "Genesis";
    }
}