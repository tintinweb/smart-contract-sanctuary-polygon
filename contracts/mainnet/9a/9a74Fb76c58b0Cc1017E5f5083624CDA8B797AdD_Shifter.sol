// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ISnowV1Program.sol";

contract Shifter is ISnowV1Program {
    uint8 private lastIndex;
    uint8 private spriteIndex;
    
    function name() external pure returns (string memory) {
        return "Shifter";
    }

    function run(uint256[64] memory canvas, uint8 lastUpdatedIndex)
        external
        returns (uint8 index, uint256 value)
    {
        index = 8;
        value = canvas[lastIndex] * 2**2;
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