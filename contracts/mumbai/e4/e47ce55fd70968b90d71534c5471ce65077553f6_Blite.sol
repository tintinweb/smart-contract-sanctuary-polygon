/**
 *Submitted for verification at polygonscan.com on 2022-05-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Blite  {
    address public owner;
    string public name;
    uint256 public totalBlites;
    mapping(uint256 => string) blites;

    event BliteAdded(address indexed owner, uint256 indexed bliteId);

    constructor() public{
        name = "Blite";
        owner = msg.sender;
        totalBlites = 1;
    }

    function storeBlite(string memory hash) public{
        blites[totalBlites] = hash;

        emit BliteAdded(msg.sender, totalBlites);
        totalBlites += 1;
    }

    function getBlite(uint256 bliteId) public view returns(string memory){
        return blites[bliteId];
    }

    function getTotalBlites() public view returns(uint256){
        return totalBlites;
    }
}