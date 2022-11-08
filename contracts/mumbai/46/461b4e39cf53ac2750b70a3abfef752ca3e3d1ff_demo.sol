/**
 *Submitted for verification at polygonscan.com on 2022-11-07
*/

//SPDX-License-Identifier:GPL-3.0
pragma solidity ^0.8.7;
contract demo{
    uint amount;
 receive() external payable{
amount+=msg.value;
 }
 function transfer(address _user) public payable{
     payable(_user).transfer(amount);
 }
}