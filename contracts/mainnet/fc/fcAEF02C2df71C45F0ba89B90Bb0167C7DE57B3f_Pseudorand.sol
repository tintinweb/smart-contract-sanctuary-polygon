// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

library Pseudorand {
    function pseudorand(bytes calldata extra) external view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, extra)));
    }
}