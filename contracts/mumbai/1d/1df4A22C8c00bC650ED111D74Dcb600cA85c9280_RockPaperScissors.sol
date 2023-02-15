/**
 *Submitted for verification at polygonscan.com on 2023-02-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RockPaperScissors {
    
    address public player1;
    address public player2;
    uint public player1Choice;
    uint public player2Choice;
    bool public gameStarted;
    bool public gameOver;
    address public winner;
    
    event GameStart(address player1, address player2);
    event GameResult(address winner, address loser, uint winnerChoice, uint loserChoice);
    
    function startGame() public {
        require(gameStarted == false, "Game already started");
        player1 = msg.sender;
        gameStarted = true;
        emit GameStart(player1, player2);
    }
    
    function playGame(uint _player2Choice) public {
        require(gameStarted == true, "Game has not started yet");
        require(gameOver == false, "Game is over");
        require(msg.sender != player1, "You cannot be Player 1");
        require(_player2Choice == 1 || _player2Choice == 2 || _player2Choice == 3, "Invalid choice");
        player2 = msg.sender;
        player2Choice = _player2Choice;
        player1Choice = rand();
        uint result = checkResult(player1Choice, player2Choice);
        if (result == 1) {
            winner = player1;
            emit GameResult(winner, player2, player1Choice, player2Choice);
        } else if (result == 2) {
            winner = player2;
            emit GameResult(winner, player1, player2Choice, player1Choice);
        } else {
            emit GameResult(address(0), address(0), player1Choice, player2Choice);
        }
        gameOver = true;
    }
    
    function rand() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, player1))) % 3 + 1;
    }
    
    function checkResult(uint _player1Choice, uint _player2Choice) private pure returns (uint) {
        if (_player1Choice == _player2Choice) {
            return 0;
        } else if ((_player1Choice == 1 && _player2Choice == 2) || (_player1Choice == 2 && _player2Choice == 3) || (_player1Choice == 3 && _player2Choice == 1)) {
            return 1;
        } else {
            return 2;
        }
    }
}