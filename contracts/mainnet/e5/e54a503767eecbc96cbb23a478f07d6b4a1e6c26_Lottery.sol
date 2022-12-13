/**
 *Submitted for verification at polygonscan.com on 2022-12-13
*/

//SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

contract Lottery{
    address[] players;

    function enter() public payable{
        require(msg.value > .01 ether);
        players.push(msg.sender);
    }

    function random() private view returns(uint){
        return uint (keccak256(abi.encode(block.timestamp,  players)));
    }

    function pickWinner() public {
        uint index = random() % players.length;
        payable (players[index]).transfer(address(this).balance);
        players = new address[](0);
    }

    function theplayers() public view returns (address[] memory) {
        return players;
    }
}