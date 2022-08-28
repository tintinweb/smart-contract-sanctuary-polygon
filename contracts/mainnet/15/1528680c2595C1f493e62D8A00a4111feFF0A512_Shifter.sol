// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ISnowV1Program.sol";

contract Shifter is ISnowV1Program {
    function name() external pure returns (string memory) {
        return "Shifter";
    }

    function rightShift(uint256 x, uint256 n) public pure returns (uint256 result) {
        assembly {
            result := shl(n, x)
        }
    }

    function run(uint256[64] memory canvas, uint8 lastUpdatedIndex)
        external
        pure
        returns (uint8 index, uint256 value)
    {
        index = 57;
        value = rightShift(8, canvas[57]);
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