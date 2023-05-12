// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract RandomNumberGenerator {
  uint256 internal Number = 195688264568759;

  function randomNumberGenerator(uint8 number) external view returns (uint8) {
    return (
      uint8(
        uint256(
          keccak256(
            abi.encodePacked(block.timestamp, block.number, Number * number)
          )
        )
      )
    );
  }
}