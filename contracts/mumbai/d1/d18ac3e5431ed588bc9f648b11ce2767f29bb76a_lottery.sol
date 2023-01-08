/**
 *Submitted for verification at polygonscan.com on 2023-01-07
*/

// SPDX-License-Identifier: GPL-3.0

 pragma solidity ^0.8.17;

contract lottery{

     address public manager;
     address payable[] public players;


     constructor(){
         manager = msg.sender;
     }
       function alreadyEntered() view private returns(bool){
           for(uint i=0;i<players.length;i++){
               if(players[i]==msg.sender){
                   return true;
               }
               return false;
           }
       }

     function enter()  payable public{
         require(msg.sender != manager,"manager cannot enter");
         require(alreadyEntered() == false,"player already entered");
         require(msg.value >= 1 ether,"minimum amount must be paid");
         players.push(payable(msg.sender));
     } 

     function random() view private returns(uint){
         return uint(sha256(abi.encodePacked(block.difficulty,block.number,players)));
     }
     function pickWinner() public {
         require(msg.sender == manager," Only manager can pick the winner");
         uint index = random()%players.length;// winner index
         address contractAdderss = address(this);
         players[index].transfer(contractAdderss.balance);
         players = new address payable[](0);
     }
     

     function getPlayer() view public returns(address payable[] memory){
         return players;
     }
}