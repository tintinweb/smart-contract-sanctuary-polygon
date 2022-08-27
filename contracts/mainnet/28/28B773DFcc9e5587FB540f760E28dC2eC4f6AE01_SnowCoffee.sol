/**
 *Submitted for verification at polygonscan.com on 2022-08-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface Snow {
    function name() external view returns (string memory);
}

contract SnowCoffee {
    uint256 public seed;
    string public name = "SnowCoffee";

    uint256[6] sprites = [
        0x3ffc7ffe7ffe7ffe7ffe7ffe7e7e7e7e7ffe7ffe7ffe7ffe7ffe3ffc0000,
        0x3ffc7ffe7fe67fe67ffe7ffe7ffe7ffe7ffe7ffe67fe67fe7ffe3ffc0000,
        0x3ffc7ffe7fe67fe67ffe7ffe7e7e7e7e7ffe7ffe67fe67fe7ffe3ffc0000,
        0x3ffc7ffe67e667e67ffe7ffe7ffe7ffe7ffe7ffe67e667e67ffe3ffc0000,
        0x3ffc7ffe67e667e67ffe7ffe7e7e7e7e7ffe7ffe67e667e67ffe3ffc0000,
        0x3ffc7ffe67e667e67ffe7ffe666666667ffe7ffe67e667e67ffe3ffc0000
    ];

    constructor() {
        seed = block.timestamp;
    }

    function run(uint256[64] memory canvas, uint8 lastUpdatedIndex) external returns(uint8 index, uint256 value) {
        seed += block.timestamp;
        uint256 sprite = sprites[(uint256(keccak256(abi.encodePacked(
            tx.origin,
            blockhash(block.number - 1),
            block.timestamp,
            msg.sender,
            seed
        )))) % 5];
        uint8 lastIndex = (lastUpdatedIndex + 1) % 64;
        return (lastIndex, sprite);
    }
}