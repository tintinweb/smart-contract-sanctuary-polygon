// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../ISnowV1Program.sol";

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
            0x0ff008100800080008000ff000100010001008100ff0000000000000,
            0xfffffffffffff7eff3eff5eff6eff76ff7aff7cff7eff7eff7efffffffffffff,
            0x03e00410041004100410041004100410041003e0000000000000,
            0x080808080808080808080808088809480a280c18000000000000,
            0xffffffffff7ffe7ffd7ffb7fff7fff7fff7fff7fff7fff7ffc1fffffffffffff
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