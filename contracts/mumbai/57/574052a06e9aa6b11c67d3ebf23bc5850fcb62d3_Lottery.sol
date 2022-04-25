/**
 *Submitted for verification at polygonscan.com on 2022-04-24
*/

//SPDX-License-Identifier: MIT 

pragma solidity ^0.8.0;

contract Lottery{
    address[] public players;
    address[] public winners;
    uint public pool = 0;

    uint public constant CAP_AMOUNT = 100;
    uint public constant PRICE = 1;

    function getPool() public view returns (uint) {
        return pool;
    }

    function enter() public payable {
        require(address(this).balance >= msg.value, "Address: insufficient balance");
        require(msg.value >= 1 ether, "Must enter with at least 1 MATIC");
        pool += msg.value;
        for(uint i = 0 ether; i < msg.value; i++) {
            players.push(msg.sender);
        }
        if(pool >= CAP_AMOUNT) {
            //pickWinner();
        }
    }

    function random() private view returns(uint){
        return  uint (keccak256(abi.encode(block.timestamp, players)));
    }

    function pickWinner() public {
        uint winnerIdx = random() % players.length;
        winners.push(players[winnerIdx]);
        payable (players[winnerIdx]).transfer(CAP_AMOUNT);
        players = new address[](0);
        pool = 0;
    }
}