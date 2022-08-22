//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


contract Game {
    mapping(address => uint256) public players;

    constructor() {
        players[msg.sender] = 0;
    }

    function ping() public returns (uint) {
        players[msg.sender] = players[msg.sender] + 1;
        return players[msg.sender];
    }
}