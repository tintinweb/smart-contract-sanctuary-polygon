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
        uint256 raffleId;
        uint256 tokenId;
        uint256 ticketPrice;
        uint256 maxTickets;
        uint256 ticketsSold;
        uint256 endTime;
        bool isActive;
        address creator;
        address winner;
        address[] participants;
        mapping(address => uint256) ticketsPurchased;
    }

    uint256 private raffleIdCounter;
    uint256 private serviceFeePercentage;
    mapping(address => bool) public admins;
    mapping(uint256 => Raffle) public raffles;
    mapping(address => uint256[]) private userRaffles;
    mapping(uint256 => bool) private raffleExists;

    event RaffleCreated(uint256 raffleId, uint256 tokenId, uint256 ticketPrice, uint256 maxTickets, uint256 endTime, address creator);
    event RaffleTicketPurchased(uint256 raffleId, address participant, uint256 numTickets, uint256 paymentAmount);
    event RaffleWinnerSelected(uint256 raffleId, address winner);
    event RaffleRemoved(uint256 raffleId);
    event ServiceFeeWithdrawn(uint256 amount);

    modifier onlyAdmin() {
        require(admins[msg.sender], "Only admins can perform this action.");
        _;
    }

    constructor() {
        admins[msg.sender] = true;
        serviceFeePercentage = 5;
    }

    function addAdmin(address newAdmin) external onlyAdmin {
        admins[newAdmin] = true;
    }

    function removeAdmin(address admin) external onlyAdmin {
        require(msg.sender != admin, "Cannot remove yourself as an admin.");
        admins[admin] = false;
    }

    function createRaffle(address nftAddress, uint256 nftId, uint256 ticketPrice, uint256 maxTickets, uint256 durationMinutes) external {
        require(maxTickets > 0, "Invalid max tickets.");
        require(ticketPrice > 0, "Invalid ticket price.");
        require(IERC721(nftAddress).ownerOf(nftId) == msg.sender, "You must own the token.");

        uint256 raffleId = ++raffleIdCounter;
        uint256 endTime = block.timestamp + (durationMinutes * 1 minutes);
        Raffle storage newRaffle = raffles[raffleId];
        newRaffle.raffleId = raffleId;
        newRaffle.tokenId = nftId;
        newRaffle.ticketPrice = ticketPrice;
        newRaffle.maxTickets = maxTickets;
        newRaffle.ticketsSold = 0;
        newRaffle.endTime = endTime;
        newRaffle.isActive = true;
        newRaffle.creator = msg.sender;
        raffleExists[raffleId] = true;
        userRaffles[msg.sender].push(raffleId);

        emit RaffleCreated(raffleId, nftId, ticketPrice, maxTickets, endTime, msg.sender);
    }

    function purchaseTickets(uint256 raffleId, uint256 numTickets) external payable {
        require(raffleExists[raffleId], "Raffle does not exist.");
        Raffle storage raffle = raffles[raffleId];
        require(raffle.isActive, "Raffle is not active.");
        require(numTickets > 0, "Invalid number of tickets to purchase.");
        require(raffle.ticketsSold + numTickets <= raffle.maxTickets, "Exceeded maximum tickets.");
        require(msg.value >= raffle.ticketPrice * numTickets, "Insufficient funds.");

        raffle.ticketsSold += numTickets;
        raffle.ticketsPurchased[msg.sender] += numTickets;
        raffle.participants.push(msg.sender);
        emit RaffleTicketPurchased(raffleId, msg.sender, numTickets, msg.value);

        if (msg.value > raffle.ticketPrice * numTickets) {
            uint256 refundAmount = msg.value - (raffle.ticketPrice * numTickets);
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
        raffle.winner = winner;
        emit RaffleWinnerSelected(raffleId, winner);
    }

    function generateRandomWinner(uint256 raffleId) internal view returns (address) {
        uint256 randomNum = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, raffleId)));
        uint256 index = randomNum % raffles[raffleId].maxTickets;

        return raffles[raffleId].participants[index];
    }

    function getRaffleDetails(uint256 raffleId) external view returns (uint256, uint256, uint256, uint256, uint256, bool, address, address, uint256) {
        Raffle storage raffle = raffles[raffleId];
        return (
            raffle.tokenId,
            raffle.ticketPrice,
            raffle.maxTickets,
            raffle.ticketsSold,
            raffle.endTime,
            raffle.isActive,
            raffle.creator,
            raffle.winner,
            raffle.participants.length
        );
    }

    function getUserRaffles(address user) external view returns (uint256[] memory) {
        return userRaffles[user];
    }

    function removeRaffle(uint256 raffleId) external {
        require(raffleExists[raffleId], "Raffle does not exist.");
        Raffle storage raffle = raffles[raffleId];
        require(!raffle.isActive, "Active raffles cannot be removed.");
        require(raffle.ticketsSold == 0, "Tickets have been sold, cannot remove the raffle.");

        uint256[] storage userRaffleList = userRaffles[raffle.creator];
        for (uint256 i = 0; i < userRaffleList.length; i++) {
            if (userRaffleList[i] == raffleId) {
                userRaffleList[i] = userRaffleList[userRaffleList.length - 1];
                userRaffleList.pop();
                break;
            }
        }

        delete raffles[raffleId];
        delete raffleExists[raffleId];

        emit RaffleRemoved(raffleId);
    }

    function withdrawServiceFee() external onlyAdmin {
        uint256 serviceFeeAmount = address(this).balance * serviceFeePercentage / 100;
        payable(msg.sender).transfer(serviceFeeAmount);
        emit ServiceFeeWithdrawn(serviceFeeAmount);
    }
}