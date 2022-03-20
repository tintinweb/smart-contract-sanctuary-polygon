/**
 *Submitted for verification at polygonscan.com on 2022-03-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract BrewDatabaseLite{
    //Code made by BobochDBrew.eth @bobochdbrew
    string[] public rows;
    address public owner;
    uint256 public length;
    constructor(){
        owner = msg.sender; 
    }
    function add(string memory x) public{
        require(owner == msg.sender, "Not owner");
        rows.push(x);
        length++;
    }
    function remove(uint256 i) public{
        require(owner == msg.sender, "Not owner");
        for (uint j = i; j<rows.length-1; j++){
            rows[j] = rows[j+1];
        }
        delete rows[rows.length-1];
        length--;
    }
    function setOwner(address x) public{
        require(owner == msg.sender, "Not owner");
        owner = x;
    }
}