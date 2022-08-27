/**
 *Submitted for verification at polygonscan.com on 2022-08-27
*/

// File: contracts/ISnowV1Program.sol


pragma solidity ^0.8.13;

interface ISnowV1Program {
    function name() external view returns (string memory);

    function run(uint256[64] memory canvas, uint8 lastUpdatedIndex)
        external
        returns (uint8 index, uint256 value);
}

// File: contracts/SnowBall.sol


pragma solidity ^0.8.13;


contract SnowBall is ISnowV1Program {
    uint8 private lastIndex;
    uint8 private spriteIndex;

    function name() external pure returns (string memory) {
        return "snowball";
    }

    function run(uint256[64] memory, uint8)
        external
        returns (uint8 index, uint256 value)
    {
        uint256[5] memory sprites = [
            // Sprites created with https://snow.computer/operators
            0x7fff7fff7fff7fff7fff7fff4541545545557fff7fff7fff7fff7fff0000,
            0x97a29436941cf7089408978800000000000000000000,
            0x757c5754555475540000000000000000000000000000,
            0x3c7800003c7824483c780000000003800000600c1e7803c000000000,
            0xffffffffc387ffffc387dbb7c387fffffffffc7ffffffffff81fc7e79ff3ffff
        ];

        spriteIndex = (spriteIndex + 1) % 5;
        lastIndex = (lastIndex + 1) % 64;

        return (lastIndex, sprites[spriteIndex]);
    }
}