/**
 *Submitted for verification at polygonscan.com on 2023-04-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library OddAndEven {
    error InvalidHand();
    error InvalidGuesses();

    function winner(
        uint8 playerHand,
        uint8 playerGuess,
        uint8 houseHand
    ) external pure returns (string memory) {
        if (playerHand < 0 || playerHand > 5 || houseHand < 0 || houseHand > 5)
            revert InvalidHand();
        if (playerGuess != 0 && playerGuess != 1) revert InvalidGuesses();

        uint8 sum = playerHand + houseHand;
        if (sum % 2 == 0 && playerGuess == 0) {
            return "Player wins";
        } else if (sum % 2 == 1 && playerGuess == 1) {
            return "Player wins";
        } else {
            return "House wins";
        }
    }
}