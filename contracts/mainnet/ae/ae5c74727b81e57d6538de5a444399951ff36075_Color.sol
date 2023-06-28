/**
 *Submitted for verification at polygonscan.com on 2023-06-28
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Color {

    //Decleration of variables
    mapping(address=> string[]) PlayersColors;
    //Gets Color of Message Sender
    function GetMyColors() view public returns(string[] memory){
        return PlayersColors[msg.sender];
    }
    //Get Colors of specific Player
    function GetColorsOfOwner(address _address) view public returns(string[] memory){
        return PlayersColors[_address];
    }
    //Register Color only for self
    function AddColor(string memory _color) public {
        PlayersColors[msg.sender].push(_color);
    }



}