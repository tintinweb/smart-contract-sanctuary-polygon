/**
 *Submitted for verification at polygonscan.com on 2022-09-02
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

contract PathOfNicolas {
  mapping(address => Player) players;


  function GetUserInfo(address wallet) public view returns (Player memory){
       Player memory player = players[wallet];
       return player;
  }

  function RegisterInGame() external 
  {
     require(!players[msg.sender].register, "already register");
      Player storage player = players[msg.sender];
      player.register = true;
      for (uint i = 0; i < player.buildings.length; i++) {
            Building storage building = player.buildings[i];
            building.level = 1;
        }
  }
  
  function UpdateBuilding(uint _id) external 
  {
     require(players[msg.sender].register, "you are not register");
      Player storage player = players[msg.sender];
      require(player.buildings[_id].finish<block.timestamp, "Update still pending");
     player.buildings[_id].start = block.timestamp;
     player.buildings[_id].finish = block.timestamp+(5*player.buildings[_id].level);
     player.buildings[_id].pending = true;
      
  }

    function CompleteUpdateBuilding(uint _id) external 
  {
     require(players[msg.sender].register, "you are not register");

      Player storage player = players[msg.sender];
      require(player.buildings[_id].finish<block.timestamp, "Still Updating");
       require(player.buildings[_id].pending, "Update First");
     player.buildings[_id].level +=1;
     player.buildings[_id].start = 0;
     player.buildings[_id].finish = 0;
     player.buildings[_id].pending = false;
      
  }

   function CurrectTime() public view returns(uint)
  {
     return block.timestamp;
      
  }

  }


struct Player{
  bool register;
  Building[3] buildings;
}

struct Building{
  uint level;
  bool pending;
  uint start;
  uint finish;

}