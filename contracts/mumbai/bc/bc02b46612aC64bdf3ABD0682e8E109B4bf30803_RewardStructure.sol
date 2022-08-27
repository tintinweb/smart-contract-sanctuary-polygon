// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/**
 * @title Get a specific distribution for an amount of players;
 * @author Pedrojok01
 * @notice Allows to change the rewards distribution depending on players's numbers.
 * @notice Edit the rewards structure to match any desired pattern.
 * @dev Return <rewards> - array containing the wanted repartition (numbers represent pourcentage)
 */

library RewardStructure {
    /// @dev Enter an integer to select the wanted repartition (3 || 5 || 10)
    function getRewardStructure(uint8 x) public pure returns (uint8[10] memory rewards) {
        require(x == 10 || x == 5 || x == 3, "invalid value");
        if (x == 10) {
            rewards = [31, 20, 15, 10, 8, 6, 4, 3, 2, 1];
        } else if (x == 5) {
            rewards = [45, 25, 15, 10, 5, 0, 0, 0, 0, 0];
        } else if (x == 3) {
            rewards = [50, 30, 20, 0, 0, 0, 0, 0, 0, 0];
        }
        return rewards;
    }
}