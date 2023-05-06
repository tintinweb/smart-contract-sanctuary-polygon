/**
 *Submitted for verification at polygonscan.com on 2023-05-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Raffle {
    address public owner;
    uint public ticketPrice;
    uint public totalTickets;
    uint public endBlock;
    uint public winner;
    mapping(address => uint) public balances;
    mapping(uint => address) public tickets;

    constructor(uint _ticketPrice, uint _totalTickets, uint _endBlock) {
        owner = msg.sender;
        ticketPrice = _ticketPrice;
        totalTickets = _totalTickets;
        endBlock = _endBlock;
    }

    function purchaseTicket() public payable {
        require(msg.value == ticketPrice, "Incorrect ticket price");
        require(block.number < endBlock, "Raffle has ended");
        require(totalTickets > 0, "No tickets remaining");

        balances[msg.sender] += 1;
        uint ticketId = totalTickets;
        tickets[ticketId] = msg.sender;
        totalTickets -= 1;
    }

    function endRaffle() public {
        require(msg.sender == owner, "Only the owner can end the raffle");
        require(block.number >= endBlock, "Raffle has not ended yet");

        uint winningNumber = uint(keccak256(abi.encodePacked(blockhash(endBlock), block.timestamp))) % totalTickets;
        winner = winningNumber;
        address winningAddress = tickets[winningNumber];
        payable(winningAddress).transfer(address(this).balance);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getWinner() public view returns (address) {
        return tickets[winner];
    }
}