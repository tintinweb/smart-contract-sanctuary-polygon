// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ISnowV1Program {
    function name() external view returns (string memory);
    function run(uint256[64] memory canvas, uint8 lastUpdatedIndex) external returns (uint8 index, uint256 value);
}

contract ATinyDino is ISnowV1Program {
    function name() external pure returns (string memory) {
        return "ATinyDino";
    }

    function run(uint256[64] calldata canvas, uint8) external pure returns (uint8 index, uint256 value) {
        uint256 sprites = 0x000000000000000003f0035003f003f003c003c007e01fc00240000000000000;

        // Drawing has already been painted
        // Draw 16x16 on QR to bully <3
        return (48, sprites);
    }
}