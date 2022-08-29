// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ISnowV1Program.sol";

contract Arrow is ISnowV1Program {
    uint8 private lastIndex;
    uint8 private spriteIndex;

    function name() external pure returns (string memory) {
        return "Arrow";
    }

    function run(uint256[64] memory canvas, uint8 lastIndex)
        external
        returns (uint8 index, uint256 value)
    {
        uint256[2] memory sprites = [
            // Sprites created with https://snow.computer/operators
            0xe000f000f8007c003e001f000f8007c003e001f000f8007c003e001f000f0007,
            0xe000f000f8007c003e001f000f8007c103e301f700ff007f003f007f00ff01ff
        ];

        if (canvas[61] != sprites[1]) {
            return (61, sprites[1]);
        } else if (canvas[52] != sprites[0]) {
            return (52, sprites[0]);
        } else if (canvas[43] != sprites[0]) {
            return (43, ~sprites[1]);
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