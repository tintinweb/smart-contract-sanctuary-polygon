/**
 *Submitted for verification at polygonscan.com on 2022-08-28
*/

// Sources flattened with hardhat v2.10.2 https://hardhat.org

// File contracts/snow.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ISnowV1Program {
    function name() external view returns (string memory);

    function run(uint256[64] memory canvas, uint8 lastUpdatedIndex)
        external
        returns (uint8 index, uint256 value);
}

contract RockPaperScissor is ISnowV1Program {

    function name() external pure returns (string memory) {
        return "RockPaperScissor";
    }

    function run(uint256[64] calldata canvas, uint8 lastUpdatedIndex)
        external pure
        returns (uint8 index, uint256 value)
    {
        uint256[3] memory rps = [
            0x00000000000003c006600c30101830042024206437c810080ff8000000000000, // rock
            0xffffe007dfebb05dbfedc00df3fbf657e7f7cc2f9fef9443bfdd922dc003ffff, // paper
            0x0000000000000000303848444882797c0600797c488248443038000000000000 // scissor
        ];

        uint rpsIndex = (lastUpdatedIndex+2) % 3;
        uint prevIndexValue = canvas[lastUpdatedIndex] % 3;

        if (prevIndexValue == 0) {
          if (rpsIndex == 1) {
            return (lastUpdatedIndex, rps[rpsIndex]);
          } else {
            return (lastUpdatedIndex, rps[0]);
          }
        }

        if (prevIndexValue == 1) {
          if (rpsIndex == 2) {
            return (lastUpdatedIndex, rps[rpsIndex]);
          } else {
            return (lastUpdatedIndex, rps[1]);
          }
        }

        if (prevIndexValue == 2) {
          if (rpsIndex == 0) {
            return (lastUpdatedIndex, rps[rpsIndex]);
          } else {
            return (lastUpdatedIndex, rps[2]);
          }
        }
    }
}