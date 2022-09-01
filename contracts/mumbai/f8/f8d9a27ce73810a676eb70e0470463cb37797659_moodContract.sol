/**
 *Submitted for verification at polygonscan.com on 2022-08-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract moodContract{

    string mood;
    
    function setMood(string memory _mood) public{
        mood = _mood;
    }

    function getMood() public view returns(string memory){
        return mood;
    } 
}