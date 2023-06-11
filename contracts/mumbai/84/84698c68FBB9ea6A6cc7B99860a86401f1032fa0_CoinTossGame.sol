// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract CoinTossGame {
    enum GameResult { Pending, Win, Lose }
    
    struct Game {
        bytes32 commitment;
        uint256 betAmount;
        bool revealed;
        GameResult result;
    }
    
    mapping(uint256 => Game) public games;
    uint256 public gameId;
    address public owner;
    uint256 public houseBalance;
    
    constructor() {
        owner = msg.sender;
    }
    
    function startGame(bytes32 commitment) external payable {
        require(msg.value > 0, "Invalid bet amount.");
        
        gameId++;
        games[gameId] = Game(commitment, msg.value, false, GameResult.Pending);
    }
    
    function reveal(uint256 gameId, uint256 randomValue) external {
        Game storage game = games[gameId];
        require(game.commitment != 0, "Invalid game ID.");
        require(!game.revealed, "Game already revealed.");
        
        bytes32 expectedCommitment = keccak256(abi.encodePacked(randomValue));
        require(game.commitment == expectedCommitment, "Invalid commitment.");
        
        game.revealed = true;
        
        if (randomValue % 2 == 0) {
            game.result = GameResult.Win;
            uint256 winnings = game.betAmount * 2;
            payable(msg.sender).transfer(winnings);
        } else {
            game.result = GameResult.Lose;
            houseBalance += game.betAmount;
        }
        
        emit GameResultEvent(gameId, game.result);
    }
    
    function depositHouseBalance() external payable {
        require(msg.sender == owner, "Only the contract owner can deposit to the house balance.");
        
        houseBalance += msg.value;
    }
    
    function withdrawHouseBalance() external {
        require(msg.sender == owner, "Only the contract owner can withdraw from the house balance.");
        require(houseBalance > 0, "No balance to withdraw.");
        
        uint256 balance = houseBalance;
        houseBalance = 0;
        payable(msg.sender).transfer(balance);
    }
    
    function withdrawFunds() external {
        uint256 balance = address(this).balance - houseBalance;
        require(balance > 0, "No balance to withdraw.");
        
        payable(msg.sender).transfer(balance);
    }
    
    event GameResultEvent(uint256 indexed gameId, GameResult result);
}