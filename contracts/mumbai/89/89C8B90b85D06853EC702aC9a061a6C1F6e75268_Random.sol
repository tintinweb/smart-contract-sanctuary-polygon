//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

library Random {
    function pseudorandom(uint seed) public view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, seed)));
    }

    function pseudorandoms(uint seed, uint8 count) public view returns (uint[] memory) {
        uint[] memory randoms = new uint[](count);
        for (uint8 i = 0; i < count; i++) {
            if (i==0) {
                randoms[i] = pseudorandom(seed);
            } else {
                randoms[i] = pseudorandom(randoms[i-1]);
            }
        }

        return randoms;
    }
}