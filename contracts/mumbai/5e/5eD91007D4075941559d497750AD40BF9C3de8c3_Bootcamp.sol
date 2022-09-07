// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

 contract Bootcamp{
     string userName="BlocOrbit";

     function getUserName() public view returns(string memory){
         return userName;
     } 
     function setUserName( string memory newUserName) public {
         userName=newUserName;
     }
     }