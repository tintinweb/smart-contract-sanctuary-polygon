/**
 *Submitted for verification at polygonscan.com on 2022-08-27
*/

pragma solidity ^0.8.13;
// SPDX-License-Identifier: UNLICENSED


interface ISnowV1Program {
    function name() external view returns (string memory);

    function run(uint256[64] memory canvas, uint8 lastUpdatedIndex)
        external
        returns (uint8 index, uint256 value);
}




contract helloWorld is ISnowV1Program {
    uint8 private lastIndex;
    uint256 private spriteIndex;
    

    function name() external pure returns (string memory) {
        return "Sprite";
    }

    function run(uint256[64] memory canvas, uint8 lastUpdatedIndex)
        external
        returns (uint8 index, uint256 value)
    {
        
        uint256[5] memory sprites = [
            // Sprites created with https://snow.computer/operators
            0x1ff8200420042004200420042004200420042004200420042004200420041ff8,
            0x0100030001000100010001000100010001000100010001000100010001000100,
            0x1ff8200420042004200420042004200420042004200420042004200420041ff8,
            0x0100030001000100010001000100010001000100010001000100010001000100,
            0x1ff8200420042004200420042004200420042004200420042004200420041ff8
        ];

        uint256 VeryRandom = uint256(
            keccak256(
                abi.encodePacked(msg.sender, block.timestamp, lastUpdatedIndex)
            )
        );

        spriteIndex = (VeryRandom + 1) % 5;
        lastIndex = (lastIndex + 1) % 64;

        return (lastIndex, sprites[spriteIndex]);
    }
}