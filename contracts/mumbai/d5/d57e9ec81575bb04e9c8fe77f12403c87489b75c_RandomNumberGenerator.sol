/**
 *Submitted for verification at polygonscan.com on 2022-12-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract RandomNumberGenerator {
    /* Abdul Qadir Anwar 1912136*/

    uint256 public randomNumber;

    constructor() {
        randomNumber = generateRandomNumber();
    }

    function generateRandomNumber() private view returns (uint256) {
        bytes24 randomValue;
        assembly {
            randomValue := mload(0x40)
        }
        return
            1 +
            (uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        randomValue
                    )
                )
            ) % 100);
    }

    function generateNewRandomNumber() public {
        randomNumber = generateRandomNumber();
    }
}