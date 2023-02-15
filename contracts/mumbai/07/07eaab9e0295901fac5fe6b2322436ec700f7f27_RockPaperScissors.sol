/**
 *Submitted for verification at polygonscan.com on 2023-02-15
*/

pragma solidity ^0.8.0;

contract RockPaperScissors {
    address public player1;
    address public player2;
    uint public player1Choice;
    uint public player2Choice;
    uint public result;
    bool public gameEnded;
    
    function startGame() public {
        require(player1 == address(0), "Game in progress.");
        player1 = msg.sender;
    }
    
    function play(uint choice) public {
        require(!gameEnded, "Game has ended.");
        require(msg.sender != player1, "Player 1 cannot be player 2.");
        require(choice >= 1 && choice <= 3, "Invalid choice.");
        require(player2 == address(0), "Player 2 has already played.");
        player2 = msg.sender;
        player2Choice = choice;
        generateResult();
    }
    
    function generateResult() private {
        player1Choice = rand();
        result = (player1Choice - player2Choice + 3) % 3;
        gameEnded = true;
    }
    
    function rand() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % 3 + 1;
    }
    
    function resetGame() public {
        require(gameEnded, "Game has not ended.");
        player1 = address(0);
        player2 = address(0);
        player1Choice = 0;
        player2Choice = 0;
        result = 0;
        gameEnded = false;
    }
}