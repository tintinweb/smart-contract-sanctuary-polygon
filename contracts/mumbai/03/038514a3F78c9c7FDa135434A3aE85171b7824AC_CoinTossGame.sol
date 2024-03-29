// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";

contract CoinTossGame is ReentrancyGuard {
    address public owner;
    uint256 public houseBalance;

    enum GameResult { Pending, Win, Lose }

    event GameResultEvent(uint256 indexed gameId, GameResult result);

    constructor() {
        owner = msg.sender;
    }

    function depositHouseBalance() external payable {
        require(msg.sender == owner, "Only owner can deposit to house balance");
        houseBalance += msg.value;
    }

    function startGame(uint256 gameId, uint8 chosenSide) external payable nonReentrant {
        require(msg.value > 0, "Bet amount must be greater than zero");

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
        // Generate a random result here
        // Replace with your own logic or use an external randomness oracle
        return block.timestamp % 2 == 0;
    }
}

pragma solidity ^0.8.0;

contract ReentrancyGuard {
    bool private locked;

    modifier nonReentrant() {
        require(!locked, "Reentrant call");
        locked = true;
        _;
        locked = false;
    }
}