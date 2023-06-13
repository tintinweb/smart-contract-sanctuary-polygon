/**
 *Submitted for verification at polygonscan.com on 2023-06-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract RafflePanel {
    struct Raffle {
        uint256 tokenId;
        uint256 ticketPrice;
        uint256 maxTickets;
        uint256 ticketsSold;
        bool isActive;
        address creator;
    }

    mapping(address => bool) public admins;
    mapping(uint256 => Raffle) public raffles;
    mapping(uint256 => mapping(address => uint256)) public ticketsPurchased;

    event RaffleCreated(uint256 raffleId, uint256 tokenId, uint256 ticketPrice, uint256 maxTickets, address creator);
    event RaffleTicketPurchased(uint256 raffleId, address participant, uint256 numTickets);
    event RaffleWinnerSelected(uint256 raffleId, address winner);

    modifier onlyAdmin() {
        require(admins[msg.sender], "Only admins can perform this action.");
        _;
    }

    constructor() {
        admins[msg.sender] = true; // Set the contract deployer as an admin
    }

    function addAdmin(address newAdmin) external onlyAdmin {
        admins[newAdmin] = true;
    }

    function removeAdmin(address admin) external onlyAdmin {
        require(msg.sender != admin, "Cannot remove yourself as an admin.");
        admins[admin] = false;
    }

    function createRaffle(address nftAddress, uint256 nftId, uint256 ticketPrice, uint256 maxTickets) external {
    require(maxTickets > 0, "Invalid max tickets.");
    require(ticketPrice > 0, "Invalid ticket price.");
    require(IERC721(nftAddress).ownerOf(nftId) == msg.sender, "You must own the token.");

    uint256 raffleId = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, nftAddress, nftId)));
    require(raffles[raffleId].tokenId == 0, "Raffle already exists.");

    Raffle storage newRaffle = raffles[raffleId];
    newRaffle.tokenId = nftId;
    newRaffle.ticketPrice = ticketPrice;
    newRaffle.maxTickets = maxTickets;
    newRaffle.ticketsSold = 0;
    newRaffle.isActive = true;
    newRaffle.creator = msg.sender;

    emit RaffleCreated(raffleId, nftId, ticketPrice, maxTickets, msg.sender);
}


    function purchaseTickets(uint256 raffleId, uint256 numTickets) external payable {
        Raffle storage raffle = raffles[raffleId];
        require(raffle.isActive, "Raffle is not active.");
        require(raffle.ticketPrice > 0, "Raffle does not exist.");
        require(numTickets > 0, "Invalid number of tickets to purchase.");
        require(raffle.ticketsSold + numTickets <= raffle.maxTickets, "Exceeded maximum tickets.");

        uint256 totalPrice = raffle.ticketPrice * numTickets;
        require(msg.value >= totalPrice, "Insufficient funds.");

        raffle.ticketsSold += numTickets;
        ticketsPurchased[raffleId][msg.sender] += numTickets;
        emit RaffleTicketPurchased(raffleId, msg.sender, numTickets);

        if (msg.value > totalPrice) {
            uint256 refundAmount = msg.value - totalPrice;
            payable(msg.sender).transfer(refundAmount);
        }

        if (raffle.ticketsSold == raffle.maxTickets) {
            selectWinner(raffleId);
        }
    }

    function selectWinner(uint256 raffleId) internal {
        Raffle storage raffle = raffles[raffleId];
        require(raffle.isActive, "Raffle is not active.");
        require(raffle.ticketsSold == raffle.maxTickets, "All tickets must be sold.");

        address winner = generateRandomWinner(raffleId);
        IERC721(raffle.creator).transferFrom(raffle.creator, winner, raffle.tokenId);

        raffle.isActive = false;
        emit RaffleWinnerSelected(raffleId, winner);
    }

    function generateRandomWinner(uint256 raffleId) internal view returns (address) {
        uint256 randomNum = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, raffleId)));
        uint256 index = randomNum % raffles[raffleId].maxTickets;

        address[] memory participants = new address[](raffles[raffleId].ticketsSold);

        for (uint256 i = 0; i < raffles[raffleId].ticketsSold; i++) {
            address participant = getParticipantByIndex(raffleId, i);
            participants[i] = participant;
        }

        return participants[index];
    }

    function getParticipantByIndex(uint256 raffleId, uint256 index) internal view returns (address) {
        Raffle storage raffle = raffles[raffleId];
        address[] memory participants = new address[](raffle.ticketsSold);

        for (uint256 i = 0; i < raffle.ticketsSold; i++) {
            address participant = address(0);
            while (participant == address(0)) {
                participant = getNextParticipant(raffleId, i);
            }
            participants[i] = participant;
        }

        return participants[index];
    }

    function getNextParticipant(uint256 raffleId, uint256 startIndex) internal view returns (address) {
        Raffle storage raffle = raffles[raffleId];
        for (uint256 i = startIndex; i < raffle.ticketsSold; i++) {
            address participant = getParticipantByIndex(raffleId, i);
            if (ticketsPurchased[raffleId][participant] > 0) {
                return participant;
            }
        }
        return address(0);
    }

    function getRaffleDetails(uint256 raffleId) external view returns (uint256, uint256, uint256, uint256, bool, address) {
        Raffle memory raffle = raffles[raffleId];
        return (raffle.tokenId, raffle.ticketPrice, raffle.maxTickets, raffle.ticketsSold, raffle.isActive, raffle.creator);
    }

    function withdraw() external onlyAdmin {
        payable(msg.sender).transfer(address(this).balance);
    }
}