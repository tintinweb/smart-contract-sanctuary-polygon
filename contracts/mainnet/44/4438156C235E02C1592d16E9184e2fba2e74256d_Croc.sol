pragma solidity ^0.8.13;

import "./ISnowV1Program.sol";

contract Croc is ISnowV1Program {
    function name() external pure returns (string memory) {
        return "Croc"; 
    }

    function run(uint256[64] memory canvas, uint8 lastUpdatedIndex)
        external
        returns (uint8 index, uint256 value) {
            uint256 croc = 0x000000000000000003f0035003f003f003c003c007e01fc00240000000000000;
            lastUpdatedIndex = (lastUpdatedIndex + 1) % 64;
            return(lastUpdatedIndex, croc);
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