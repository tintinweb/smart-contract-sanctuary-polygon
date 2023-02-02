// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library String {
    function equals(
        string memory self,
        string memory s
    ) public pure returns (bool) {
        return
            keccak256(abi.encodePacked(self)) == keccak256(abi.encodePacked(s));
    }

    function concat(
        string memory self,
        string memory s
    ) public pure returns (string memory) {
        return string(abi.encodePacked(self, s));
    }
}