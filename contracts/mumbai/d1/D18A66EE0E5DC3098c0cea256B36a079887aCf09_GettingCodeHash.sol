/**
 *Submitted for verification at polygonscan.com on 2023-05-08
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

contract GettingCodeHash {
    function getCodeHash(address target) external view returns (bytes32 codehash) {
        assembly {
            codehash := extcodehash(target)
        }
    }
}