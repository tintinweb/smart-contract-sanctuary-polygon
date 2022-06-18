///SPDX-License-Identifier: GPL-3.0
pragma solidity  ^ 0.8.0 ;
//contract to store creators limited to pilot;
contract Pilot{
struct Creator{
    address creatorAddress;
    string profileId;   
    bool isActive;
}

uint256 public creatorCount;
mapping(address=>Creator) public creatorList;
address[] public creators ;
function createAccount (string memory Id) public{
    creatorList[msg.sender].creatorAddress = msg.sender;
    creatorList[msg.sender].profileId  = Id;
    creatorList[msg.sender].isActive = true;
    creators.push(msg.sender);
     creatorCount++;
}
function deleteAccount ()public{
    creatorList[msg.sender].isActive = false;
}
function getCreatorId(address id)public view returns(string memory){
    return creatorList[id].profileId;
}

}