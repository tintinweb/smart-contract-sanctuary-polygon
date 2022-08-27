// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ISnowV1Program} from "./interfaces/ISnowV1Program.sol";

contract SnowProgram is ISnowV1Program {

    function name() external view returns (string memory) {
        return "Oighty";
    }

    function run(uint256[64] memory canvas, uint8 lastUpdatedIndex)
        external
        returns (uint8 index, uint256 value) {
        return ((lastUpdatedIndex * 2 + 1) % 64, uint256(keccak256(abi.encodePacked(canvas[lastUpdatedIndex],"oighty.eth"))));
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