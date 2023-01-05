/**
 *Submitted for verification at polygonscan.com on 2023-01-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Color{
    mapping(address=> string[]) PlayersColors;
    function GetmyColors() view public returns(string[] memory){
        return PlayersColors[msg.sender];
    }
    function GetColorsofOwner(address _address) view public returns(string[] memory){
        return PlayersColors[_address];
    }
    function AddColor(string memory _color) public {
        PlayersColors[msg.sender].push(_color);
    }
}