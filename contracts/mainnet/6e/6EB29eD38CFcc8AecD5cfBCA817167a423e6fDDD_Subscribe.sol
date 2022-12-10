/**
 *Submitted for verification at polygonscan.com on 2022-12-10
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

/*
* Author : Mantas Noreika
* Date   : 12/2022
* Objective => Subscribe Service (Smart Contract)
*/

 contract Subscribe{
  
  address owner;                                                    // owner wallet
  address assistance = 0xf93b7fbA85A96367DDb4e8d9944f4c1f476a4dDC; // Network wallet
 
  mapping(address => bytes32) recordHash;
  mapping( address => mapping(bytes32=>uint)) hashTime;

 constructor(){
     owner=msg.sender;                                          // assign owner wallet
 }
 
  modifier onlyBy(){
  require (owner==msg.sender);
  _;
  }

  modifier andAssistance(){
  require((assistance==msg.sender) || (owner==msg.sender),"! Owner or Assistance Allowed");
  _;
  }

    event Subscribed(address indexed user,bytes32 hash);
    event Unsubscribed(address indexed user,bytes32 hash);
    event Duration(address indexed user,uint time);
    event Deleted(address indexed user);

 function subscribe(address spender,string memory word)public onlyBy returns (bytes32){

    if(subscription(spender)>0)
    {
        revert("Subscription Already Exist");
    }
    
    recordHash[spender] = bytes32(keccak256(abi.encodePacked(msg.sender, word)));        // Map address to hash
    emit Subscribed(spender,recordHash[spender]);       // emit event that address subscribed
    return recordHash[spender];
    }
    function unsubscribe(address spender)public onlyBy{
    hashTime[spender][recordHash[spender]]=0;
    recordHash[spender]=0;
    emit Unsubscribed(spender, recordHash[spender]);
    }
    function subscribeDuration(address client,uint duration)public andAssistance returns(bool){
    uint expire = block.timestamp + duration;
    require(!(recordHash[client]>0),"Subscription Exist Already");
    recordHash[client] = bytes32(keccak256(abi.encodePacked(msg.sender, expire)));
    hashTime[client][recordHash[client]] = expire;  // Record Time End of subscription
    emit Duration(client, expire);
    return true;
    }
    function subscription(address client)public andAssistance view returns(bytes32){
    return recordHash[client];
    }
    function subscriptionTime(address client)public andAssistance view returns(uint){
    require(hashTime[client][recordHash[client]]>0,"! Subscription Not Exist");
    return hashTime[client][recordHash[client]];
    }

   function getOwner()public view  returns(address creator){
   creator=owner;
   }
 }