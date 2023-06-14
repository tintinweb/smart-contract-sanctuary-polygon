// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract CoinTossGame {
    address public owner;
    uint256 public houseBalance;
    uint256 public gameIdCounter;

    enum GameResult { Pending, Win, Lose }

    event GameResultEvent(uint256 indexed gameId, GameResult result);

    constructor() {
        owner = msg.sender;
        gameIdCounter = 1; // Initialize the game ID counter to 1
    }

    function depositHouseBalance() external payable {
        require(msg.sender == owner, "Only owner can deposit to house balance");
        houseBalance += msg.value;
    }

    function startGame(uint8 chosenSide) external payable {
        require(msg.value > 0, "Bet amount must be greater than zero");
        require(chosenSide == 1 || chosenSide == 2, "Invalid choice");

        uint256 gameId = gameIdCounter; // Assign the current game ID
        gameIdCounter++; // Increment the game ID counter for the next game

        // Perform game logic here, determining the result
        GameResult result;
        if (chosenSide == 1) {
            result = getRandomResult() ? GameResult.Win : GameResult.Lose;
        } else if (chosenSide == 2) {
            result = getRandomResult() ? GameResult.Lose : GameResult.Win;
        }

        // Emit the game result event
        emit GameResultEvent(gameId, result);

        if (result == GameResult.Win) {
            // Calculate the winnings and transfer to the player
            uint256 winnings = msg.value * 2;
            payable(msg.sender).transfer(winnings);
        } else if (result == GameResult.Lose) {
            // Increment the house balance with the lost bet amount
            houseBalance += msg.value;
        }
    }

    function withdrawFunds(uint256 amount) external {
        require(msg.sender == owner, "Only owner can withdraw funds");
        require(amount <= address(this).balance, "Insufficient contract balance");
        payable(msg.sender).transfer(amount);
    }

    function withdrawHouseBalance() external {
        require(msg.sender == owner, "Only owner can withdraw house balance");
        require(houseBalance > 0, "House balance is zero");
        payable(msg.sender).transfer(houseBalance);
        houseBalance = 0;
    }

    function getRandomResult() private view returns (bool) {
        bytes32 blockHash = blockhash(block.number - 1); // Get the hash of the previous block

        // Generate a random number from the block hash
        uint256 randomNumber = uint256(blockHash);

        // Convert the random number to a boolean result
        return (randomNumber % 2 == 0);
    }
}