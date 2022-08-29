// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ISnowV1Program.sol";

contract Arrow is ISnowV1Program {
    uint8 private lastIndex;
    uint8 private spriteIndex;

    function name() external pure returns (string memory) {
        return "Arrow";
    }

    function reverse(uint256 x) public pure returns (uint256) {
        x = (x & 0x5555555555555555555555555555555555555555555555555555555555555555) << 1 |
            (x & 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA) >> 1;
        x = (x & 0x3333333333333333333333333333333333333333333333333333333333333333) << 2 |
            (x & 0xCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC) >> 2;
        x = (x & 0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F) << 4 |
            (x & 0xF0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0) >> 4;
        x = (x & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) << 8 |
            (x & 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00) >> 8;
        x = (x & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) << 16 |
            (x & 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000) >> 16;
        x = (x & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32 |
            (x & 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000) >> 32;
        x = (x & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64 |
            (x & 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000) >> 64;
        x = (x & 0x00000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) << 128 |
            (x & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000000000000000000000000000) >> 128;
        return x;
    }

    function run(uint256[64] memory canvas, uint8 lastIndex)
        external
        returns (uint8 index, uint256 value)
    {
        uint256[2] memory sprites = [
            // Sprites created with https://snow.computer/operators
            0xe000f000f8007c003e001f000f8007c003e001f000f8007c003e001f000f0007, // Diagonal Line
            0xe000f000f8007c003e001f000f8007c103e301f700ff007f003f007f00ff01ff  // Downwards Arrow down 
        ];

        if (canvas[61] != sprites[1]) { // Downright Arrow
            return (61, sprites[1]);
        } else if (canvas[43] != reverse(sprites[1])) { // Upsidedown Arrow
            return (43, reverse(sprites[1]));
        } else if (canvas[52] != sprites[0]) { // Diagonal Line
            return (52, sprites[0]);
        } 
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ISnowV1Program {
    function name() external view returns (string memory);

    function run(uint256[64] memory canvas, uint8 lastUpdatedIndex)
        external
        returns (uint8 index, uint256 value);
}