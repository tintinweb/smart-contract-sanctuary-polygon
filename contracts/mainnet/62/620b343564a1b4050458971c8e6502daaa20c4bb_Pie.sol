// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ISnowV1Program.sol";

contract Pie is ISnowV1Program {
    uint8 private lastIndex;
    uint8 private spriteIndex;

    function name() external pure returns (string memory) {
        return "Pie";
    }

    function run(uint256[64] memory, uint8)
        external
        returns (uint8 index, uint256 value)
    {
        uint256[5] memory sprites = [
            0x0490024804900ff81004222242218001ffff8001422221c420041ff800000000,
            0xfb6ffdb7fb6ff007effbddddbdde7ffe00007ffebdddde3bdffbe007ffffffff,
            0x0490024804900ff81004222242218001ffff8001422221c420041ff800000000,
            0xfb6ffdb7fb6ff007effbddddbdde7ffe00007ffebdddde3bdffbe007ffffffff,
            0x0490024804900ff81004222242218001ffff8001422221c420041ff800000000
        ];

        spriteIndex = (spriteIndex + 1) % 5;
        lastIndex = (lastIndex + 1) % 64;

        return (lastIndex, sprites[spriteIndex]);
    }
}