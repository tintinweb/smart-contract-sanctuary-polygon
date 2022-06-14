// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

library Position {
    function getPositionId(
        address self_,
        int24 lowerTick_,
        int24 upperTick_
    ) public pure returns (bytes32 positionId) {
        return keccak256(abi.encodePacked(self_, lowerTick_, upperTick_));
    }
}