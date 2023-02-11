/**
 *Submitted for verification at polygonscan.com on 2023-02-11
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Color {
//Declaration of variables
mapping(address=> string[]) public PlayerColors;
// get colors of msg.sender
function GetMyColors() view public returns(string[] memory){

    return PlayerColors[msg.sender];
}
// get colors of specific players
    function GetColorsOfOwner(address _address) view public returns(string[] memory){
        return PlayerColors[_address];

    }
// register color - only for self
    function AddColor(string memory _color) public {
        PlayerColors[msg.sender].push(_color);
    }
}