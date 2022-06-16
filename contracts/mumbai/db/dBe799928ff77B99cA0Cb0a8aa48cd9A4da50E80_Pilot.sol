///SPDX-License-Identifier: GPL-3.0
pragma solidity  ^ 0.8.0 ;
//contract to store creators limited to pilot;
contract Pilot{
struct Creator{
    address creatorAddress;   
    bool isActive;
}

uint256 public creatorCount;
mapping(uint256=>Creator) public creatorList;
address[] public creators ;
function createAccount () public{
    creatorList[creatorCount].creatorAddress = msg.sender;
    creatorList[creatorCount].isActive = true;
    creators.push(msg.sender);
     creatorCount++;
}
function deleteAccount (uint id)public{
    creatorList[id].isActive = false;
}
function getCreator(uint id)public view returns(Creator memory){
    return creatorList[id];
}

}