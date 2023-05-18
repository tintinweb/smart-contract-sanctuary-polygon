/**
 *Submitted for verification at polygonscan.com on 2023-05-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address approved);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract Marketplace {
    struct Item {
        address seller;
        uint256 price;
        bool isForSale;
        bool isAuction;
        uint256 startTime;
        uint256 endTime;
        uint256 highestBid;
        address highestBidder;
    }

    mapping(uint256 => Item) public items;
    IERC721 public collection;
    address public marketplaceOwner;

    event ItemListed(uint256 indexed itemId, address indexed seller, uint256 price, bool isAuction);
    event ItemSold(uint256 indexed itemId, address indexed seller, address indexed buyer, uint256 price);
    event AuctionStarted(uint256 indexed itemId, address indexed seller, uint256 startTime, uint256 endTime);
    event AuctionEnded(uint256 indexed itemId, address indexed seller, address indexed winner, uint256 price);

    modifier onlyMarketplaceOwner() {
        require(msg.sender == marketplaceOwner, "Only marketplace owner can call this function");
        _;
    }
    
    modifier onlyValidCollection() {
        require(msg.sender == address(collection), "Invalid collection");
        _;
    }

    constructor() {
        collection = IERC721(0x564e6588DAfA2F79c5805e07860CB869AEdb33d9);
        marketplaceOwner = msg.sender;
    }

    function listForSale(uint256 itemId, uint256 price) external onlyValidCollection {
        require(items[itemId].seller == address(0), "Item already listed");
        require(collection.ownerOf(itemId) == msg.sender, "You don't own this item");

        // Переводим NFT на контракт маркетплейса
        collection.transferFrom(msg.sender, address(this), itemId);

        items[itemId] = Item(msg.sender, price, true, false, 0, 0, 0, address(0));
        emit ItemListed(itemId, msg.sender, price, false);
    }

    function buy(uint256 itemId) external payable {
        Item storage item = items[itemId];
        require(item.isForSale, "Item is not for sale");
        require(item.seller != address(0), "Item does not exist");
        require(msg.value >= item.price, "Insufficient funds");

        item.isForSale = false;
        emit ItemSold(itemId, item.seller, msg.sender, item.price);

        // Переводим NFT обратно продавцу
        collection.transferFrom(address(this), msg.sender, itemId);

        payable(item.seller).transfer(item.price);
        if (msg.value > item.price) {
            payable(msg.sender).transfer(msg.value - item.price);
        }
    }

    function startAuction(uint256 itemId, uint256 startTime, uint256 endTime) external onlyValidCollection {
        require(items[itemId].seller == address(0), "Item already listed");
        require(collection.ownerOf(itemId) == msg.sender, "You don't own this item");
        require(startTime < endTime, "Invalid auction period");

        // Переводим NFT на контракт маркетплейса
        collection.transferFrom(msg.sender, address(this), itemId);

        items[itemId] = Item(msg.sender, 0, false, true, startTime, endTime, 0, address(0));
        emit AuctionStarted(itemId, msg.sender, startTime, endTime);
    }

    function placeBid(uint256 itemId) external payable {
        Item storage item = items[itemId];
        require(item.isAuction, "Auction is not active");
        require(item.seller != address(0), "Item does not exist");
        require(block.timestamp >= item.startTime && block.timestamp <= item.endTime, "Auction period has ended");
        require(msg.value > item.highestBid, "Bid too low");

        if (item.highestBidder != address(0)) {
            payable(item.highestBidder).transfer(item.highestBid);
        }

        item.highestBid = msg.value;
        item.highestBidder = msg.sender;
    }

    function endAuction(uint256 itemId) external onlyMarketplaceOwner {
        Item storage item = items[itemId];
        require(item.isAuction, "Auction is not active");
        require(item.seller != address(0), "Item does not exist");
        require(block.timestamp > item.endTime, "Auction period has not ended");

        address winner = item.highestBidder;
        uint256 winningBid = item.highestBid;
        item.isAuction = false;
        item.isForSale = false;
        item.highestBid = 0;
        item.highestBidder = address(0);
        emit AuctionEnded(itemId, item.seller, winner, winningBid);

        // Переводим NFT победителю аукциона
        collection.transferFrom(address(this), winner, itemId);

        if (winner != address(0)) {
            payable(item.seller).transfer(winningBid);
        }
    }

    function cancelSale(uint256 itemId) external {
        Item storage item = items[itemId];
        require(item.seller == msg.sender, "You are not the seller");

        item.isForSale = false;
        if (item.isAuction) {
            item.isAuction = false;
            item.highestBid = 0;
            item.highestBidder = address(0);
        }

        // Переводим NFT обратно продавцу
        collection.transferFrom(address(this), msg.sender, itemId);
    }

    function setMarketplaceOwner(address newOwner) external onlyMarketplaceOwner {
        marketplaceOwner = newOwner;
    }
}