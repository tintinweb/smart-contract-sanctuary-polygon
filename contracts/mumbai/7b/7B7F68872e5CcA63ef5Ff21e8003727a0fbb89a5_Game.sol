//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Game {
    mapping(address => uint256) public players;
    event GameStarted(address _player);
    event LevelUp(address _player, uint256 _level);

    constructor() {
        players[msg.sender] = 0;
        emit GameStarted(msg.sender);
    }

    function count() public returns (uint256) {
        players[msg.sender] = players[msg.sender] + 1;
        if (players[msg.sender] % 2 == 0) {
            emit LevelUp(msg.sender, players[msg.sender] / 2);
        }
        return players[msg.sender];
    }

    function reset() public {
        players[msg.sender] = 0;
    }
}