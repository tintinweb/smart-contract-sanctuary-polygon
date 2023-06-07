// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract GameContract {
    uint256 public gameReward; // Reward amount for winning the game
    uint256 public ethConversionRate; // Conversion rate from score to ETH

    mapping(address => uint256) public userScores; // Mapping to track user scores

    // Event to emit when a user wins the game
    event GameWon(address indexed player, uint256 score, uint256 reward);

    // Constructor to set the initial game reward and conversion rate
    constructor(uint256 initialReward, uint256 conversionRate) {
        gameReward = initialReward;
        ethConversionRate = conversionRate;
    }

    // Function to start the game
    function startGame(uint256 score) external {
        // Update the user's score
        userScores[msg.sender] = score;

        // Calculate the reward in ETH
        uint256 rewardInEth = calculateReward(score);

        // Emit the GameWon event
        emit GameWon(msg.sender, score, rewardInEth);
    }

    // Function to calculate the reward based on the score
    function calculateReward(uint256 score) internal view returns (uint256) {
        // Calculate the reward based on the score and the conversion rate
        return score * ethConversionRate;
    }

    // Function to update the game reward
    function updateReward(uint256 newReward) external {
        gameReward = newReward;
    }

    // Function to update the conversion rate
    function updateConversionRate(uint256 newRate) external {
        ethConversionRate = newRate;
    }

    // Function to get the score of a specific user
    function getScore(address user) external view returns (uint256) {
        return userScores[user];
    }
}