//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;


contract GoonsGameEvents {
    event GameStart(uint  time, address user);
    event GameComplete(uint  time, address user);
    event RankBattleStart(uint  time, address user);
    event FriendBattleStart(uint  time, address user);
    event DeckCreation(uint  time, address user);
    event LevelUp(uint  time, address user);

     function gameStart(uint  time, address user) external {
          emit GameStart(  time,  user);
     }

     function gameComplete(uint time,address user) external {
          emit GameComplete(  time,  user);
     }

     function rankBattleStart(uint time,address user) external {
          emit RankBattleStart(  time,  user);
     }

     function friendBattleStart(uint time,address user) external {
          emit FriendBattleStart(  time,  user);
     }

     function deckCreation(uint  time, address user) external {
          emit DeckCreation( time,  user);
     }

     function gameLevelUp(uint time, address user) external {
          emit LevelUp(time, user);
     }
}