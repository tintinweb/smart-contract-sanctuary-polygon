/**
 *Submitted for verification at polygonscan.com on 2023-07-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0<0.9.0;

contract ChatApplication{


struct user{
    string name;
    bool userActive;
    address userAddress;
    Files[] fileIdList;
}

struct Files{
    uint256 fileId;
}

struct message{
    address sender;
    uint256 timestamp;
    string msgs;
}

struct FileStoage{
    address sender;
    address reciever;
    string fileHash;
    bool recieverPaid;
    bool senderConfirmation;
    bool startChat;
}

FileStoage[] storeFile;

struct AllUserStuck{
    string name;
    address accountAddress;
}


AllUserStuck[] getAllUsers;

mapping(address => user) public userList;
mapping(bytes32 => message[]) allMessage;
//check user exist

function checkUserexists(address pubkey) public view returns(bool){
    return userList[pubkey].userAddress != address(0);
}

//create accout



function createAccount() external {
    require(checkUserexists(msg.sender) == false,"User already exist");
    userList[msg.sender].userActive=false; 
    userList[msg.sender].userAddress=msg.sender; 

    string memory name = "";
    getAllUsers.push(AllUserStuck(name, msg.sender));
}

//get username

// function getUsername(address pubkey) public view returns(string memory){
//     require(checkUserexists(pubkey),"User user is not registered");
//     require(bytes(userList[pubkey].name).length>0,"User not entered name");
//     return userList[pubkey].name;
// }

// set user details

function setUserDetails(string memory name) external {
    require(checkUserexists(msg.sender) == true,"User not exist");
    require(userList[msg.sender].userActive == false,"User already exist");

    userList[msg.sender].name = name;
   // getAllUsers.push(AllUserStuck(name, msg.sender));
}

// All users

// function getAllAppUsers() public view returns(AllUserStuck[] memory){
//     return getAllUsers;
// }


function sendFileToSomeone(address reciever,string memory file)external{
    require(checkUserexists(msg.sender) == true,"User Not exist,Login First");
    require(checkUserexists(reciever) == true,"Reciever Not exist, Make Reciever Login");
    
    Files memory fileId = Files(storeFile.length);

    storeFile.push(FileStoage(msg.sender,reciever,file,false,false,true));
    userList[msg.sender].fileIdList.push(fileId);

}

function getMyFileId() external view returns(Files[] memory){
    return userList[msg.sender].fileIdList;
} 

function getMyFileDetailById(uint256 id) external view returns(FileStoage memory){
    require(storeFile[id].sender == msg.sender || (storeFile[id].reciever == msg.sender && storeFile[id].senderConfirmation),"Unauthorized");
    return storeFile[id];
} 

function _getChatCode(address pubkey1, address pubkey2, uint256 fileId) internal pure returns(bytes32){
    if(pubkey1<pubkey2){
        return keccak256(abi.encodePacked(pubkey1,pubkey2,fileId));
    }else{
        return keccak256(abi.encodePacked(pubkey2,pubkey1,fileId));
    }
}

function sendmessage(string calldata _msg,uint256 fileId) external{
    require(storeFile[fileId].sender == msg.sender || storeFile[fileId].reciever == msg.sender,"Unauthorized");
address reciever;

if(storeFile[fileId].sender == msg.sender){
    reciever=storeFile[fileId].reciever;
}else{
    reciever=storeFile[fileId].sender;
}
    bytes32 chatCode = _getChatCode(msg.sender, reciever, fileId);
    message memory newMsg = message(msg.sender, block.timestamp, _msg);
    allMessage[chatCode].push(newMsg);

}

function readMessage(uint256 fileId) external view returns(message[] memory){
      require(storeFile[fileId].sender == msg.sender || storeFile[fileId].reciever == msg.sender,"Unauthorized");
address reciever;

if(storeFile[fileId].sender == msg.sender){
    reciever=storeFile[fileId].reciever;
}else{
    reciever=storeFile[fileId].sender;
}
    bytes32 chatCode = _getChatCode(msg.sender, reciever,fileId);
    return allMessage[chatCode];  
}
}