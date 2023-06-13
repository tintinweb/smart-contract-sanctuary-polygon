/**
 *Submitted for verification at polygonscan.com on 2023-06-13
*/

// SPDX-License-Identifier:  MIT
pragma solidity ^0.8.0;

contract MinterRoleDecoder {
    function decodeMinterRole(bytes32 minterRole) public pure returns (string memory) {
        bytes memory bytesData = new bytes(32);
        for (uint256 i = 0; i < 32; i++) {
            bytesData[i] = minterRole[i];
        }
        return string(bytesData);
    }

    function decodeBurnerRole(bytes32 BurnerRole) public pure returns (string memory) {
        bytes memory bytesData = new bytes(32);
        for (uint256 i = 0; i < 32; i++) {
            bytesData[i] = BurnerRole[i];
        }
        return string(bytesData);
    }
}