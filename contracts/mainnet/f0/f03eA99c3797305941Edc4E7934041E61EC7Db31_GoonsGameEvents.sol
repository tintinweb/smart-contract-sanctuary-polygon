//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;


contract GoonsGameEvents {
    event GameLaunch(uint time, address user);
    event RankedBattleStart(uint time, address user);
    event FriendBattleStart(uint time, address user);
    event DeckCreation(uint time, address user);
    event LevelUp(uint time, address user);

     function gameLaunch(uint  time, address user) external {
          emit GameLaunch(time,  user);
     }

     function rankedBattleStart(uint time,address user) external {
          emit RankedBattleStart(time,  user);
     }

     function friendBattleStart(uint time,address user) external {
          emit FriendBattleStart(time,  user);
     }

     function deckCreation(uint  time, address user) external {
          emit DeckCreation(time,  user);
     }

     function levelUp(uint time, address user) external {
          emit LevelUp(time, user);
     }
}