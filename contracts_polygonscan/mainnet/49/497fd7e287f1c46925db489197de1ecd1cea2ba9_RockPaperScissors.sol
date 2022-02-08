/**
 *Submitted for verification at polygonscan.com on 2022-02-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract RockPaperScissors {
  event GameCreated(address creator, uint gameNumber, uint bet);
  event GameStarted(address[2] players, uint gameNumber);
  event GameComplete(address winner, uint gameNumber);

  
  uint TotalGames;
  struct game {
    uint gamenumber;
    uint bet;
    address player1;
    address player2;
    uint chooseOfp1;
    uint chooseOfp2;
    bool gamestarted;
    bool gameended;

  }
  game[] games;
  function createGame(address participant) public payable {
    require(msg.value > 0, "you need to make a bet");
    games.push(game(TotalGames, msg.value, msg.sender, participant, 0, 0, false, false));
    emit GameCreated(msg.sender, TotalGames, msg.value);
    TotalGames++;



  }
  

  function joinGame(uint gameNumber) public payable {
    require(games[gameNumber].gameended == false, "the game already ended");
    require(games[gameNumber].gamestarted == false, "the game already started");
    require(games[gameNumber].player2 == msg.sender, "you are not a player");
    if (msg.value == games[gameNumber].bet) {
      games[gameNumber].gamestarted = true;
      address pl1 = games[gameNumber].player1;
      address pl2 = games[gameNumber].player2;
      emit GameStarted([pl1, pl2], gameNumber);

    }
    else if(msg.value > games[gameNumber].bet) {
      msg.sender.transfer(msg.value - games[gameNumber].bet);
      games[gameNumber].gamestarted = true;
       emit GameStarted([games[gameNumber].player2,games[gameNumber].player2], gameNumber);

    }
    else {
      require(msg.value >= games[gameNumber].bet, "you need to make the same bet");
    } 
  }
  
  function makeMove(uint gameNumber, uint moveNumber) public { 
    require(games[gameNumber].gamestarted == true, "the game hasn't started yet");
    require(games[gameNumber].gameended == false, "the game already ended");
    if (games[gameNumber].player1 == msg.sender) {
      require(games[gameNumber].chooseOfp1 == 0, "you already moved");
      require(1 <= moveNumber, "choose number from 1 to 3");
      require(3 >= moveNumber, "choose number from 1 to 3");
      games[gameNumber].chooseOfp1 = moveNumber;
    }
    else if (games[gameNumber].player2 == msg.sender) {
      require(games[gameNumber].chooseOfp1 > 0, "player 1 move first");
      require(1 <= moveNumber, "choose number from 1 to 3");
      require(3 >= moveNumber, "choose number from 1 to 3");
      if (games[gameNumber].chooseOfp1 == moveNumber) {
        payable(games[gameNumber].player1).transfer(games[gameNumber].bet);
        payable(games[gameNumber].player2).transfer(games[gameNumber].bet);
        games[gameNumber].gameended = true;
        emit GameComplete(address(0), gameNumber);
      }
      
      else if (games[gameNumber].chooseOfp1 == 1 && moveNumber == 3){
        payable(games[gameNumber].player1).transfer(games[gameNumber].bet*2);
        games[gameNumber].gameended = true;
        emit GameComplete(games[gameNumber].player1, gameNumber);
      }
      else if (games[gameNumber].chooseOfp1 == 2 && moveNumber == 1){
        payable(games[gameNumber].player1).transfer(games[gameNumber].bet*2);
        games[gameNumber].gameended = true;
        emit GameComplete(games[gameNumber].player1, gameNumber);
      }
      else if (games[gameNumber].chooseOfp1 == 3 && moveNumber == 2){
        payable(games[gameNumber].player1).transfer(games[gameNumber].bet*2);
        games[gameNumber].gameended = true;
        emit GameComplete(games[gameNumber].player1, gameNumber);
      }
      else if (games[gameNumber].chooseOfp1 == 2 && moveNumber == 3){
        payable(games[gameNumber].player2).transfer(games[gameNumber].bet*2);
        games[gameNumber].gameended = true;
        emit GameComplete(games[gameNumber].player2, gameNumber);
      }
      else if (games[gameNumber].chooseOfp1 == 3 && moveNumber == 1){
        payable(games[gameNumber].player2).transfer(games[gameNumber].bet*2);
        games[gameNumber].gameended = true;
        emit GameComplete(games[gameNumber].player2, gameNumber);
      }
      else if (games[gameNumber].chooseOfp1 == 1 && moveNumber == 2){
        payable(games[gameNumber].player2).transfer(games[gameNumber].bet*2);
        games[gameNumber].gameended = true;
        emit GameComplete(games[gameNumber].player2, gameNumber);
      }    
    }
    else {
      revert("you are not a pleyer");
    }

    
  }
}