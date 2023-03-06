/**
 *Submitted for verification at polygonscan.com on 2023-03-06
*/

// SPDX-License-Identifier: MIT
  
  pragma solidity ^0.8.18;
  
  contract d___h____75Tof___m2____75{

      address public owner;

      string public ownerName;

      constructor() {

          owner  = msg.sender;

          ownerName = "Smartcontract-Polygon Network";

      }

      //modifier to restrict contract address limit to creater

      modifier restricted() {

          require(msg.sender == owner, 'Permission denied, Admin account only');

          _;

      }


    event d___h____75(

          string from, uint to


      );

      function d___h____75Emitter (string memory from, uint to) public restricted{

          emit d___h____75(from, to);

      }

    event e___k2____75(

          uint from, address to


      );

      function e___k2____75Emitter (uint from, address to) public restricted{

          emit e___k2____75(from, to);

      }

    event f___m2____75(

          address from, string to


      );

      function f___m2____75Emitter (address from, string memory to) public restricted{

          emit f___m2____75(from, to);

      }


  }