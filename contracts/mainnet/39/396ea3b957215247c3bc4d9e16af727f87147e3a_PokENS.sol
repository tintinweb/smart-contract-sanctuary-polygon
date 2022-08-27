/**
 *Submitted for verification at polygonscan.com on 2022-08-27
*/

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.14;

contract PokENS {
    uint8 private lastIndex;
    uint8 private spriteIndex;

    function name() external pure returns (string memory) {
        return "PokENS";
    }

    function run(uint256[64] memory, uint8) external returns (uint8 index, uint256 value) {
        uint240[6] memory sprites = [
            0x0ff00ff00c300c300c300c300ff00ff00c000c000c000c000c000c000000,
            0x0ff00ff00c300c300c300c300c300c300c300c300c300c300ff00ff00000,
            0x0c300c300c700ce00dc00f800f000f000f800dc00ce00c700c300c300000,
            0x0ff00ff00c000c000c000c000fc00fc00c000c000c000c000ff00ff00000,
            0x0c300e300e300f300d300d300db00cb00cb00cb00c700c700c700c300000,
            0x0ff00ff00c000c000c000c000ff00ff000300030003000300ff00ff00000
        ];
        spriteIndex = (spriteIndex + 1) % 6;
        lastIndex = (lastIndex + 1) % 64;
        return (lastIndex, sprites[spriteIndex]);
    }
}