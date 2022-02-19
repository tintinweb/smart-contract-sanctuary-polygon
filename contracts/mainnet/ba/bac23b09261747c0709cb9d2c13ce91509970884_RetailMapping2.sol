/**
 *Submitted for verification at polygonscan.com on 2022-02-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

contract RetailMapping2 {

    mapping(address => string[]) public userMap;

    event UpdateMapping(address indexed from_);

    function updateMapping(string[] calldata toArray_) external {
        delete userMap[msg.sender];
        for (uint256 i = 0; i < toArray_.length; ++i) {
            bool contains = false;
            for (uint256 j = 0; j < userMap[msg.sender].length; ++j) {
                if (keccak256(bytes(userMap[msg.sender][j])) == keccak256(bytes(toArray_[i]))) {
                    contains = true;
                    break;
                }
            }

            if (contains) {
                continue;
            }

            userMap[msg.sender].push(toArray_[i]);
        }

        emit UpdateMapping(msg.sender);
    }
}