/**
 *Submitted for verification at polygonscan.com on 2022-03-13
*/

// SPDX-License-Identifier: MIT

/*
Buy lottery
get my tickets
get sold tickets
get address of the sold tickets
choose winner
*/

pragma solidity ^0.8.12;

contract JumboSimulator {
    address deployer;

    uint constant TICKET_PRICE = 0.005 ether;

    uint[] soldTickets;

    mapping(uint => address payable) soldTicketData;

    mapping(address => Customer) customerData;

    struct Customer {
        uint totalTickets;
        uint[] tickets;
    }

    string season;

    constructor(string memory _season) {
        require(bytes(_season).length > 0, "season need to be defined");
        deployer = msg.sender;
        season = _season;
    }

    function buyLotteries(uint _pieces) public payable {
        require(bytes(season).length > 0, "season not defined");
        uint totalPrices = TICKET_PRICE * _pieces;
        require(msg.value > totalPrices, "Customer don't have enough money");

        for (uint i = 0; i < _pieces; i++){
            uint ticketId = generateRandomId();
            soldTickets.push(ticketId);
            soldTicketData[ticketId] = payable(msg.sender);
            customerData[msg.sender].tickets.push(ticketId);
        }
        customerData[msg.sender].totalTickets += _pieces;
    }

    function generateRandomId() public view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, season)));
    }

    function getMyTicket() public view returns (Customer memory) {
        return customerData[msg.sender];
    }

    function getSoldTicketCount() public view returns (uint) {
        return soldTickets.length;
    }

    function getTicketOwner(uint ticketId) public view returns (address) {
        return soldTicketData[ticketId];
    }

    function chooseWinner() public onlyDeployer {
        require(bytes(season).length > 0, "Season need to be defined");
        uint winnerIndex = generateRandomId() % soldTickets.length;
        uint winnerTicketId = soldTickets[winnerIndex];
        address payable winnerAddress = soldTicketData[winnerTicketId];
        uint winnerPrice = soldTickets.length * TICKET_PRICE;
        season = "";
        winnerAddress.transfer(winnerPrice);
    }

    modifier onlyDeployer() {
        require(deployer == msg.sender, "Only deployer can do transaction");
        _;
    }
}