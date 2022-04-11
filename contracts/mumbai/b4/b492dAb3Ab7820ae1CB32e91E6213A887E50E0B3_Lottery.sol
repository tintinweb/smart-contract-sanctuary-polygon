/**
 *Submitted for verification at polygonscan.com on 2022-04-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Lottery {
    address public owner;
    address payable[] public players;
    address public winner;
    
    constructor() { 
        owner = msg.sender;
    }
    modifier onlyOwner(){
            require(msg.sender == owner);
            _;
        }

    function enter() public payable {
        require(msg.value == 0.1 ether);
        players.push(payable(msg.sender));
    }

    //only for testing, remove later
    function sendFundToContract() public payable {
        require(msg.value == 1 ether);
    }

    function random() public view returns (uint8) {
        return uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, players)))%251);
    }
    function getWinner() public view returns (address) {
        return winner;
    }

    function pickWinner() public onlyOwner{
        uint index = random() % players.length;
        
        //return each players funds
        for (uint i=0; i<players.length; i++){
            players[i].transfer(0.1 ether);
        }

        //transfer reward to the winner
        players[index].transfer(address(this).balance);
        winner = players[index];

        //reset the state of the contract
        players = new address payable[](0);
    }
    
}