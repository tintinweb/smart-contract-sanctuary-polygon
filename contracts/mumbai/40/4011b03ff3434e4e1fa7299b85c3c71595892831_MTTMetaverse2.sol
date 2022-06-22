/**
 *Submitted for verification at polygonscan.com on 2022-06-21
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

contract MTTMetaverse2{
    
   
       
    UserProfile user;
    address ownerAddress;

    // structure to save user profile date
    struct UserProfile { 
        bytes32 username;
        bytes32 characterName;
        uint256 score;
    } 
    // modifier function will make other fucntions work only if msg sent by the owner
    modifier onlyOwner {
      require(msg.sender == ownerAddress);
      _;
   }

    // calls for the first time user creates instance of contract
    constructor() {
      ownerAddress = msg.sender;
    }

    //writes when the user login
    function RegisterLogin(bytes32 name,bytes32 chName, uint256 score) public {
        user=UserProfile(name,chName, score);
    }

    function GetUserProfile() public view returns (UserProfile[] memory) {
        UserProfile[] memory userMemory;
        userMemory[0]=user;
        return userMemory;
    }
    function UpdateUserProfile(bytes32 name,bytes32 chName, uint256 score) public onlyOwner{
            user=UserProfile(name,chName, score);
    }
    function PolygonTransfer(address payable recipient, uint amount) public returns(bool){
        require(ownerAddress == msg.sender, "transfer failed because you are not the owner."); // 
        if(amount <= getBalance()) {
            recipient.transfer(amount);
            return true;
        } else {
            return false;
        }
    }
    function getBalance() public view returns (uint){
        return address(this).balance;
    }


}