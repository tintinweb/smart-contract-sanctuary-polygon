// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ISnowV1Program} from "./ISnowV1Program.sol";

contract Yo is ISnowV1Program {
    function name() external view returns (string memory) {
        return "Yo";
    }

    function run(uint256[64] calldata canvas, uint8 lastUpdatedIndex)
        external
        returns (uint8 index, uint256 value)
    {
        uint256 yo = 0x000000000000667c66c67ec63cc618c618c618c618c618c618c6187c00000000;

        return (lastUpdatedIndex + 1, yo);
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