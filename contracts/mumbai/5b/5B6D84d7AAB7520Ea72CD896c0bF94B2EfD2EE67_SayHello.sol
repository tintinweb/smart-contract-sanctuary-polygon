// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SayHello {
   
   string username;

   constructor() {
    }
   function setName(string memory _username) public {
        username = _username;
   }

   function getUser() public view returns(string memory){
       return username;
   }

}