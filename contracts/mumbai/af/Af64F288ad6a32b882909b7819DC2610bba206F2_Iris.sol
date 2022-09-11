/**
 *Submitted for verification at polygonscan.com on 2022-09-11
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Iris {
    struct User{
        string name;
        string profilepic;
        string messageLog;
        uint256 tokenId;
        bool verified;
    }
    uint256 private _tokenId;
    mapping (address => User) contactBook;
    mapping(uint256 => address) userId;
    modifier checkUserExist(){
        require(contactBook[msg.sender].tokenId >0 ,"Register First!!");
            _;
    }
    function register()external{
        require(contactBook[msg.sender].tokenId ==0,"You are already registered");
        _tokenId++;
        contactBook[msg.sender].tokenId= _tokenId;
        userId[_tokenId] = msg.sender;
    }
    function addMessage(string memory _messagLog)external checkUserExist {
        contactBook[msg.sender].messageLog =_messagLog;
    }
    function addName(string memory _name)external checkUserExist{
        contactBook[msg.sender].name =_name; 
    }
    function addProfilepic(string memory _pic)external checkUserExist{
        contactBook[msg.sender].profilepic =_pic; 
    }
    function verifyYourAccount() external checkUserExist{
        contactBook[msg.sender].verified =true;
    }
    function getUser()external view checkUserExist returns(  User memory _user) {
        return contactBook[msg.sender];

    }
    function checkTokenId(uint256 _tid)external view checkUserExist returns(address){
        require(contactBook[msg.sender].tokenId == _tokenId,"Token Id not matched");
        return userId[_tid];
        
    }
    
}