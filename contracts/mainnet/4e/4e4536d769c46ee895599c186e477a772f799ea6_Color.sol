/**
 *Submitted for verification at polygonscan.com on 2023-05-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//actual contract color
contract Color {
//declaration of variables
    mapping(address=> string[]) public PlayersColors;
// get colors of msg.sender
    function GetMyColors() view public returns (string[] memory){
        return  PlayersColors[msg.sender];
        }
// get colors of specific player
    function GetMyColors(address _address) view public returns (string[] memory){
        return  PlayersColors[_address];
        }
//register color - only for self
        function AddColor(string memory _color) public {
            PlayersColors[msg.sender].push(_color);
        }
      
}