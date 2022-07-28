/**
 *Submitted for verification at polygonscan.com on 2022-07-28
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Color {
    //variables declaration
     mapping(address => string[]) public PlayersColors;

    //client register a color
    function RegisterColor(string memory _color) public {
        PlayersColors[msg.sender].push(_color);
    } 

    function ColorCount(address _address) view public returns(uint) 
    {
        return PlayersColors[_address].length;
    }

    function GetMyColors() view public returns(string[] memory)
    {
            return PlayersColors[msg.sender];
    }
}