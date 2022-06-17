/**
 *Submitted for verification at polygonscan.com on 2022-06-16
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Lottery
{
    address     public manager;
    address     public winner;
    address[]   public players;
    
    constructor()
    {
        manager = msg.sender;
    }

    function enter() public payable 
    {
        require(msg.value > .01 ether,"Low cache");
        players.push(msg.sender);
    }

    function random() private view returns (uint)
    {
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,players)));
    }

    function pickWinner() public payable restricted
    {
        uint index = random() % players.length;     
        winner = players[index];    
        payable(players[index]).transfer(address(this).balance);
        players = new address[](0);
    }

    function getPlayers() public view returns ( address[] memory)
    {
        return players;
    }

    modifier restricted() 
    {
        require(msg.sender == manager,"You are not a manager");
        _;
    }
}