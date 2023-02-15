/**
 *Submitted for verification at polygonscan.com on 2023-02-15
*/

pragma solidity ^0.8.0;

contract RockPaperScissors {
    address public player1;
    address public player2;
    uint256 public player1Choice;
    uint256 public player2Choice;
    bool public gameFinished;

    event GameStarted(address indexed player1, address indexed player2);
    event GameFinished(address indexed winner, address indexed loser, bool indexed isDraw);

    function startGame() public {
        require(player1 == address(0), "Game has already started.");
        player1 = msg.sender;
        emit GameStarted(player1, address(0));
    }

    function playGame(uint256 choice) public {
        require(player1 != address(0), "Game has not started yet.");
        require(msg.sender != player1, "Player 1 cannot play against themselves.");
        require(player2 == address(0), "Player 2 has already played.");
        require(choice >= 1 && choice <= 3, "Invalid choice. Please choose 1, 2, or 3.");

        player2 = msg.sender;
        player2Choice = choice;

        // generate random number for player 1's choice
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 3 + 1;
        player1Choice = randomNumber;

        // determine the winner
        bool isDraw = false;
        address winner;
        address loser;
        if (player1Choice == player2Choice) {
            isDraw = true;
        } else if ((player1Choice == 1 && player2Choice == 2) || (player1Choice == 2 && player2Choice == 3) || (player1Choice == 3 && player2Choice == 1)) {
            winner = player1;
            loser = player2;
        } else {
            winner = player2;
            loser = player1;
        }

        // update gameFinished flag
        gameFinished = true;

        // emit GameFinished event
        if (isDraw) {
            emit GameFinished(address(0), address(0), true);
        } else {
            emit GameFinished(winner, loser, false);
        }
    }

    function resetGame() public {
        require(gameFinished, "Game has not finished yet.");
        player1 = address(0);
        player2 = address(0);
        player1Choice = 0;
        player2Choice = 0;
        gameFinished = false;
    }
}