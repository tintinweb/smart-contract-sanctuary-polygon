// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Interfaces/ISnowV1Program.sol";

contract OSSprite is ISnowV1Program {
    uint8 private spriteIndex;

    function name() external pure returns (string memory) {
        return "Sprite";
    }

    function run(uint256[64] memory, uint8 lastIndexChanged)
        external
        returns (uint8 index, uint256 value)
    {
        uint256[4] memory sprites = [
            0x00000000008002c002e006f00ef00ee001c03082388e1ffc1ff80ff000000000,
            0xffffffffff7ffd3ffd1ff90ff10ff11ffe3fcf7dc771e003e007f00fffffffff,
            0xfffff81ff81ff81ff81ff81ff81ff81ff81ff81ff81ff81ff81ff81ff81fffff,
            0x000007e007e007e007e007e007e007e007e007e007e007e007e007e007e00000
        ];

        spriteIndex = (spriteIndex + 1) % 4;

        return (lastIndexChanged, sprites[spriteIndex]);
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