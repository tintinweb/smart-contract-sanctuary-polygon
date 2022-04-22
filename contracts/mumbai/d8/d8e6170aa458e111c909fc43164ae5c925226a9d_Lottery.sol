/**
 *Submitted for verification at polygonscan.com on 2022-04-21
*/

//SPDX-License-Identifier: MIT 

pragma solidity ^0.8.0;

contract Lottery{
    address public custodian = 0x60bcb0Cd4E76a1E385A0bE028F99017b19266096;
    address[] public players;
    address[] public winners;

    function lottery() public {
        //custodian = msg.sender;
    }

    function enter() public payable{
        //each player is compelled to add a certain ETH to join
        require(msg.value > 1 ether);
        players.push(msg.sender);
    }

    function random() private view returns(uint){
        return  uint (keccak256(abi.encode(block.timestamp, players)));
    }

    function pickWinner() public restricted {
        uint winnerIdx = random() % players.length;
        winners.push(players[winnerIdx]);
        payable (players[winnerIdx]).transfer(100);
        players = new address[](0);
    }

    modifier restricted(){
        require(msg.sender == custodian);
        _;
    }
}