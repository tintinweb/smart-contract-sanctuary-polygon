/**
 *Submitted for verification at polygonscan.com on 2022-03-15
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

contract WolfTeam{ 

address[] public Team;


function addTeam(address newAddress) external {
        Team.push(newAddress);
}

function remove() external  {
       delete Team;
    }

 function getLength() public view returns (uint) {
        return Team.length;
    }


function getArr() public view returns (address[] memory) {
        return Team;
    }

}