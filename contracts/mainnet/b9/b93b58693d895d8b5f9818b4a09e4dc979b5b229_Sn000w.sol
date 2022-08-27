/**
 *Submitted for verification at polygonscan.com on 2022-08-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16; // (10M optimization runs)

contract Sn000w {
    function name() external pure returns (string memory) {
        return "Sn000w";
    }

    function run(uint256[64] calldata, uint8 i) external pure returns (uint8, uint256) {
        return (
            (i + 1) % 64,
            0x0000000007e007e007e007e007e007e007e007e007e007e007e007e000000000
        );
    }
}