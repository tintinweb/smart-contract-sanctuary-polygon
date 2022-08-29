/**
 *Submitted for verification at polygonscan.com on 2022-08-29
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16; // (10M optimization runs)

/// @author 0age
contract Sn000w {
    function name() external pure returns (string memory) {
        return "Sn000w";
    }

    function run(
        uint256[64] calldata canvas,
        uint8 lastIndex
    ) external pure returns (
        uint8 index,
        uint256 value
    ) { unchecked {
        // XOR each canvas value together.
        uint256 fingerprint = canvas[0];
        for (uint256 i = 1; i < 64; ++i) {
            fingerprint ^= canvas[i];
        }
        
        index = (uint8(fingerprint) + lastIndex) % 64;

        uint256 filter = 0x0000000007e007e007e007e007e007e007e007e007e007e007e007e000000000;
        value = index % 2 == 0 ?
            fingerprint & filter :
            ~(fingerprint | filter);
    } }
}