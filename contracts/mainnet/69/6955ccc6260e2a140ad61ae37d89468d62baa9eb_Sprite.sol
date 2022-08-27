/**
 *Submitted for verification at polygonscan.com on 2022-08-27
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ISnowV1Program {
    function name() external view returns (string memory);

    function run(uint256[64] memory canvas, uint8 lastUpdatedIndex)
        external
        returns (uint8 index, uint256 value);
}

contract Sprite is ISnowV1Program {
    uint8 private lastIndex;
    uint8 private spriteIndex;

    function name() external pure returns (string memory) {
        return "Sprite";
    }

    function run(uint256[64] memory, uint8)
        external
        returns (uint8 index, uint256 value)
    {
        uint256[5] memory sprites = [
            // Sprites created with https://snow.computer/operators
            0x0000000000101020084007800840102014a0102008200ba0082007c000000000,
            0x000001f00f18100c2004244c20082008210c2004200427c410040ffc00000000,
            0x000004901ff810042004222660065006508e580a4dda442203c2010200010001,
            0x000001000100010001003ff80100010001000100010001000100000000000000,
            0xfefffefffefffefffefffefffefffefffeffe00ffefffefffefffeffffffffff
        ];

        spriteIndex = (spriteIndex + 1) % 5;
        lastIndex = (lastIndex + 1) % 64;

        return (lastIndex, sprites[spriteIndex]);
    }
}