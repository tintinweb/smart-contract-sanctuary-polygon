// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TenderContract {
    address public owner;
    address public tenderer;
    mapping(uint256 => Tender) public tenders;
    uint256 public tenderCount;

    struct Tender {
        uint256 id;
        string description;
        bool closed;
        
        mapping(address => Bid) bids;
        address[] bidders;
    }

    struct Bid {
        uint256 amount;
        uint256 rating;
    }

    constructor(address _tenderer) {
        owner = msg.sender;
        tenderer = _tenderer;
        tenderCount = 0;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function.");
        _;
    }

    modifier onlyTenderer() {
        require(msg.sender == tenderer, "Only tenderer can call this function.");
        _;
    }

    function createTender(uint256 _id, string memory _description) public onlyTenderer {
        require(tenders[_id].id == 0, "Tender with the given ID already exists.");

        Tender storage newTender = tenders[_id];
        newTender.id = _id;
        newTender.description = _description;
        newTender.closed = false;
        tenderCount++;
    }

    function getTenders() public view returns (uint256[] memory) {
        uint256[] memory tenderList = new uint256[](tenderCount);
        uint256 counter = 0;
        for (uint256 i = 1; i <= tenderCount; i++) {
            if (tenders[i].id != 0) {
                tenderList[counter] = tenders[i].id;
                counter++;
            }
        }
        return tenderList;
    }

    function bidOnTender(uint256 _id, uint256 _amount, uint256 _rating) public {
        require(tenders[_id].id != 0, "Tender with the given ID does not exist.");
        require(!tenders[_id].closed, "Tender is already closed.");

        Bid storage newBid = tenders[_id].bids[msg.sender];
        newBid.amount = _amount;
        newBid.rating = _rating;

        tenders[_id].bidders.push(msg.sender);
    }

    function getBidsForTender(uint256 _id) public view returns (address[] memory, uint256[] memory, uint256[] memory) {
        require(tenders[_id].id != 0, "Tender with the given ID does not exist.");

        address[] memory bidderList = tenders[_id].bidders;
        uint256[] memory bidAmounts = new uint256[](bidderList.length);
        uint256[] memory bidRatings = new uint256[](bidderList.length);

        for (uint256 i = 0; i < bidderList.length; i++) {
            bidAmounts[i] = tenders[_id].bids[bidderList[i]].amount;
            bidRatings[i] = tenders[_id].bids[bidderList[i]].rating;
        }

        return (bidderList, bidAmounts, bidRatings);
    }

    function selectWinner(uint256 _id) public onlyTenderer {
        require(tenders[_id].id != 0, "Tender with the given ID does not exist.");
        require(!tenders[_id].closed, "Tender is already closed.");

        address winner;
        uint256 highestAmount = 0;
        uint256 highestRating = 0;
        // Iterate through all the bidders for the tender
        for (uint256 i = 0; i < tenders[_id].bidders.length; i++) {
            address bidder = tenders[_id].bidders[i];
            uint256 bidAmount = tenders[_id].bids[bidder].amount;
            uint256 bidRating = tenders[_id].bids[bidder].rating;

            // Check if the current bidder has the highest amount and rating so far
            if (bidAmount > highestAmount || (bidAmount == highestAmount && bidRating > highestRating)) {
                winner = bidder;
                highestAmount = bidAmount;
                highestRating = bidRating;
            }
        }

        // Transfer the bidding amount to the tenderer
        if (winner != address(0)) {
            address payable tendererPayable = payable(tenderer);
            tendererPayable.transfer(highestAmount);
        }

        // Mark the tender as closed
        tenders[_id].closed = true;
    }

    function closeTender(uint256 _id) public onlyTenderer {
        require(tenders[_id].id != 0, "Tender with the given ID does not exist.");
        require(!tenders[_id].closed, "Tender is already closed.");

        tenders[_id].closed = true;
    }
}