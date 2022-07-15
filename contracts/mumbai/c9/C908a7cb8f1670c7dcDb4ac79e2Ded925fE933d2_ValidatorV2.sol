//  SPDX-License-Identifier: None
pragma solidity ^0.8.0;

contract ValidatorV2 {
    function validateResult(
        uint256 dice1,
        uint256 dice2,
        uint256 dice3
    ) external pure returns (uint256) {
        uint256 leftScore = 0;
        uint256 rightScore = 0;

        // condition 1
        if (dice1 % 2 == 0) {
            leftScore += 1;
        } else {
            rightScore += 1;
        }

        // condition 2
        if (dice3 % 2 == 0) {
            rightScore += 1;
        } else {
            leftScore += 1;
        }

        // condition 3
        uint256 total = dice1 + dice2 + dice3;
        if (total % 2 == 0) {
            leftScore += 1;
        } else {
            rightScore += 1;
        }

        return leftScore > rightScore ? 0 : 1;
        // 2-2-2 1
        // 1+ / 0 +
    }
}