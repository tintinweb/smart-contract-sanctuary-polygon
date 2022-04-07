/**
 *Submitted for verification at polygonscan.com on 2022-04-06
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

contract MegaPool {

/* array of winners addresses*/

address[5] public winners;

/* assigning id numbers to the winners */

uint index;

address public owner;


mapping(uint => address) public userId;
mapping(address => bool) public registered;

constructor() {
    owner = msg.sender;
}

modifier onlyOwner() {
    require(msg.sender == owner);
    _;
}

/* admin will add the top 5 winners */

function addWinners(address _winner) public onlyOwner {
    require(registered[_winner] == false, "Already registered");
     winners[index] = _winner;
     userId[index] = _winner;
     index ++;
     registered[_winner] = true;
}

/* This function will select a random winner among the registered members */

 function random() public onlyOwner view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, winners)))%winners.length;
        // converting hash to integer
        
    }


    
}