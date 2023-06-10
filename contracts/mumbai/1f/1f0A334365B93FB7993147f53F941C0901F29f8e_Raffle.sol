// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Raffle {
    address public manager;
    address payable[] public players;
    
    constructor() {
        manager = msg.sender;
    }
    
    function enter() public payable {
        require(msg.value > 0.01 ether, "Minimum entry fee is 0.01 ether");
        players.push(payable(msg.sender));
    }
    
    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }
    
    function pickWinner() public restricted {
        require(players.length > 0, "No players in the raffle");
        
        uint256 index = random() % players.length;
        address payable winner = players[index];
        winner.transfer(address(this).balance);
        
        players = new address payable[](0); // Reset players array
    }
    
    modifier restricted() {
        require(msg.sender == manager, "Only the manager can call this function");
        _;
    }
    
    function random() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }
}