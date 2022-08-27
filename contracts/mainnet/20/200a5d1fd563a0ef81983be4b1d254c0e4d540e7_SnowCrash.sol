// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ISnowV1Program} from "./interfaces/ISnowV1Program.sol";

contract SnowCrash is ISnowV1Program {

    function name() external view returns (string memory) {
        return "SNOWCRASH";
    }

    function run(uint256[64] memory canvas, uint8 lastUpdatedIndex)
        external
        returns (uint8 index, uint256 value) {
        return ((lastUpdatedIndex + 3) % 64, uint256(bytes32("sudo rm -rf /")));
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