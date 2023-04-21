/**
 *Submitted for verification at polygonscan.com on 2023-04-20
*/

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
 pragma solidity ^0.8.6;

contract Ex{
   address public owner;
   mapping(string=>uint64) public playerMoney;
   uint RandNonce =1;

    function signIn(string memory id)public{
        require(playerMoney[id]==0);
        playerMoney[id] = 1000;
    }

    function gambling(string memory id,uint24 bettingMoney) public returns (bool){
        require(bettingMoney < playerMoney[id]);
        if(bettingMoney > playerMoney[id]){
            return false;
        }
        if(_random()){
            playerMoney[id] = playerMoney[id] + bettingMoney;
        }else{
            playerMoney[id] = playerMoney[id] - bettingMoney;
        }
        return true;
    }
    function _random() private returns(bool){
        uint256 rand = uint(keccak256(abi.encodePacked(block.timestamp,msg.sender,RandNonce))) % 2; 
        RandNonce++;
        return rand==1; 
    }
   constructor(){
    owner = msg.sender;
   }
    
}