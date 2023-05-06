/**
 *Submitted for verification at polygonscan.com on 2023-05-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Raffle {
    address public owner;
    uint public ticketPrice;
    uint public totalTickets;
    uint public remainingTickets;
    uint public endTime;
    mapping (address => uint) public balances;
    mapping (uint => address) public ticketHolders;
    uint public currentTicketId;

    constructor(uint _ticketPrice, uint _totalTickets, uint _endTime) {
        owner = msg.sender;
        ticketPrice = _ticketPrice;
        totalTickets = _totalTickets;
        remainingTickets = _totalTickets;
        endTime = _endTime;
        currentTicketId = 1;
    }

    function purchaseTicket() public payable {
        require(msg.value == ticketPrice, "Please send the exact ticket price");
        require(block.timestamp < endTime, "Raffle has already ended");
        require(remainingTickets > 0, "All tickets have been sold");
        balances[msg.sender] += msg.value;
        ticketHolders[currentTicketId] = msg.sender;
        currentTicketId++;
        remainingTickets--;
    }

    function endRaffle() public {
        require(msg.sender == owner, "Only the owner can end the raffle");
        require(block.timestamp >= endTime, "Raffle has not yet ended");

        uint winnerId = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, currentTicketId))) % currentTicketId;
        address winnerAddress = ticketHolders[winnerId];
        uint winnings = address(this).balance;
        balances[winnerAddress] += winnings;
        payable(winnerAddress).transfer(winnings);
    }

    function refund() public {
        require(block.timestamp >= endTime, "Raffle has not yet ended");
        require(remainingTickets > 0, "All tickets have been sold");
        uint amount = balances[msg.sender];
        require(amount > 0, "No refund due");
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function getTicketHolder(uint ticketId) public view returns (address) {
        require(ticketId >= 1 && ticketId <= currentTicketId - 1, "Invalid ticket ID");
        return ticketHolders[ticketId];
    }

    function getTicketCount() public view returns (uint) {
        return currentTicketId - 1;
    }

    function withdraw() public {
        require(msg.sender == owner, "Only the owner can withdraw");
        payable(owner).transfer(address(this).balance);
    }
}