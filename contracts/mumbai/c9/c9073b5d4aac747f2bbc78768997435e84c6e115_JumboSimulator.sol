/**
 *Submitted for verification at polygonscan.com on 2022-03-12
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

/*
Buy Lottery ticket
Get My tickets
Get Total ticket sold
get participant ticket
Choose Winner
*/

contract JumboSimulator {
	
	address owner;
	
	uint256 private constant TICKET_VALUE = 0.005 ether;
	uint256 private constant TAX_FEE = 0.0005 ether;

	address payable[] participantAccounts;

	uint256[] private soldLotteryTickets;

	mapping(uint256 => address payable) public participantTickets;

	mapping(address => Participant) public participantDatas;

	struct Participant {
		uint256 totalTickets;
		uint256[] tickets;
	}

	uint lotterySeason = 0;

	constructor() {
		owner = msg.sender;
	}

	function participate(uint _pieces) public payable {
        require(msg.sender != owner, "Owner can't participate");
        require(_pieces > 0, "can not buy 0 pieces");
		uint ticketFees = _pieces * TICKET_VALUE + TAX_FEE;
		require(msg.value > ticketFees, "Participant lack of money");

		participantAccounts.push(payable(msg.sender));

		for (uint i = 0; i < _pieces; i++) {
			uint256 ticketId = generateRandomId();
			soldLotteryTickets.push(ticketId);
			participantTickets[ticketId] = payable(msg.sender);
			participantDatas[msg.sender].tickets.push(ticketId);
		}

		participantDatas[msg.sender].totalTickets += _pieces;
	}

	function chooseWinner() public onlyOwner {
		uint256 winnerIndex = generateRandomId() % soldLotteryTickets.length;
		uint256 winnerId = soldLotteryTickets[winnerIndex];
		address payable winnerAddress = participantTickets[winnerId];
		uint256 winnerPrice = soldLotteryTickets.length * TICKET_VALUE;
		winnerAddress.transfer(winnerPrice);
	}


	function getMyTickets() public view returns (Participant memory) {
		return participantDatas[msg.sender];
	}

	function getTotalTicketSold() public view returns (uint) {
		return soldLotteryTickets.length;
	}

	function getParticipantTicket(uint256 _ticketID) public view returns (address) {
		return participantTickets[_ticketID];
	}

	function generateRandomId() private view returns (uint) {
		return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, lotterySeason)));
	}

	modifier onlyOwner() {
		require(msg.sender == owner, "This method is only for owner");
		_;
	}
}