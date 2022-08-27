// SPDX-License-Identifier: MIT LICENSE
// by abranti.eth
pragma solidity ^0.8.14;

import "./ISnowV1Program.sol";

contract Replicator is ISnowV1Program {
    function name() external pure returns (string memory) {
        return "Mixer";
    }

    function run(uint256[64] calldata canvas, uint8) external returns (uint8, uint256) {
        bytes32 mask = keccak256(abi.encodePacked(block.timestamp));
        
        uint sprite = uint((bytes32(canvas[0]) & mask) | (bytes32(canvas[1]) & ~mask));
        return (2, sprite);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

interface ISnowV1Program {
    function name() external view returns (string memory);

    function run(uint256[64] memory canvas, uint8 lastUpdatedIndex)
        external
        returns (uint8 index, uint256 value);
}