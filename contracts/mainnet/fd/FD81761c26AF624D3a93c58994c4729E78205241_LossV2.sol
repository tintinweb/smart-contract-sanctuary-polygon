// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface ISnowV1Program {
    function name() external view returns (string memory);

    function run(uint256[64] memory canvas, uint8 lastUpdatedIndex)
        external
        returns (uint8 index, uint256 value);
}

/// @author Mason Hall
contract LossV2 is ISnowV1Program {
    function name() external pure returns (string memory) {
        return "LossV2";
    }

    function run(uint256[64] memory canvas, uint8 lastUpdateIndex) external pure returns (uint8 index, uint256 value) {
        uint256[4] memory sprites = [
            // Sprites created with https://snow.computer/operators
            0x2000200020002000200020002000200020002000200020000000,
            0x2000200020002020202020202020202020202020202020200000,
            0x2100210021002100210021002100210021002100210021002100,
            0x20002000200020002000200020002000200023ff200020002000000000000000
        ];

        // We are paiting at the top right corner.
        if (canvas[14] != sprites[0]) {
            return (14, sprites[0]);
        } else if (canvas[15] != sprites[1]) {
            return (15, sprites[1]);
        } else if (canvas[22] != sprites[2]) {
            return (22, sprites[2]);
        } else {
            return (23, sprites[3]);
        }
    }
}