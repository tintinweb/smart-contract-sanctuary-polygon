/**
 *Submitted for verification at polygonscan.com on 2022-11-03
*/

// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.13;




contract nick{


    mapping (string => address) public nickName;

    function setNick(string calldata _nick) external{
    require(nickName[_nick] == address(0), "Nickname already exists");
    nickName[_nick]= msg.sender;
    }
}