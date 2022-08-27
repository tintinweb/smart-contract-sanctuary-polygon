// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ISnowV1Program.sol";

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
            0xffff8139bd45bd6dbd6dbf6dbf6dbf6dbf6db16db16dbd6dbd6dbd6d816dffff,
            0x00007ec642ba4292429240924092409240924e924e924292429242927e920000,
            0xffff8139bd45bd6dbd6dbf6dbf6dbf6dbf6db16db16dbd6dbd6dbd6d816dffff,
            0x00007ec642ba4292429240924092409240924e924e924292429242927e920000,
            0xffff8139bd45bd6dbd6dbf6dbf6dbf6dbf6db16db16dbd6dbd6dbd6d816dffff
        ];

        spriteIndex = (spriteIndex + 1) % 5;
        lastIndex = (lastIndex + 1) % 64;

        return (lastIndex, sprites[spriteIndex]);
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