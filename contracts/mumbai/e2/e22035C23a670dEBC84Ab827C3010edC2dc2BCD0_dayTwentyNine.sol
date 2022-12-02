/**
 *Submitted for verification at polygonscan.com on 2022-12-01
*/

//  SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract dayTwentyNine{

    address[16] players;

    function getTeamPlayers() public view returns(address[16] memory){
        return players;
    }

    function selectJerseyNumber(uint8 index) public view returns(address){
        require(index >= 0 && index < 16, "Invalid jersey number entered. Please try again!");
        
        return players[index];
    }
    
}