//  SPDX-License-Identifier: None
pragma solidity ^0.8.0;

contract Validator {
    function validateResult(
        uint256 dice1,
        uint256 dice2,
        uint256 dice3
    ) external pure returns (uint256) {
        uint256 total = dice1 + dice2 + dice3;
        if (total % 2 == 0) {
            return 0;
        }

        return 1;
    }
}