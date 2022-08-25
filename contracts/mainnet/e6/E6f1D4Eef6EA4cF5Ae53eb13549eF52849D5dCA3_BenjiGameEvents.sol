//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;


contract BenjiGameEvents{

    event GameStart(uint  time, address user);
    event GameComplete(uint  time, address user);
    event GamePaused(uint  time, address user);
    event GameLevelUp(uint  time, address user);
    event RegisterAction(string action,address user,uint time);


  function gameStart(uint  time, address user) external {
        emit GameStart(  time,  user);
   }

   function gameComplete(uint time,address user) external {
        emit GameComplete(  time,  user);
   }

   function gamePaused(uint  time, address user) external {
        emit GamePaused( time,  user);
   }

   function gameLevelUp(uint time, address user) external {
        emit GameLevelUp(time, user);
   }

    function registerAction(string memory  action,address user,uint time) external {
        emit RegisterAction(action,user,time);
    }

    function versionRecipient() external pure  returns (string memory) {
        return "1";
    }
 }