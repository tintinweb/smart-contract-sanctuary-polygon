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
    mapping(address => mapping(uint256 => bool)) public isItemApproved;
    address public marketplaceOwner;

    event ItemListed(uint256 indexed itemId, address indexed seller, uint256 price, bool isAuction);
    event ItemSold(uint256 indexed itemId, address indexed seller, address indexed buyer, uint256 price);
    event AuctionStarted(uint256 indexed itemId, address indexed seller, uint256 startTime, uint256 endTime);
    event AuctionEnded(uint256 indexed itemId, address indexed seller, address indexed winner, uint256 price);
    event AuctionCancelled(uint256 indexed itemId, address indexed seller);

    modifier onlyMarketplaceOwner() {
        require(msg.sender == marketplaceOwner, "Only marketplace owner can call this function");
        _;
    }

    constructor() {
        marketplaceOwner = msg.sender;
    }

    function listForSale(address nftContract, uint256 itemId, uint256 price) external {
        IERC721 nft = IERC721(nftContract);
        require(items[itemId].seller == address(0), "Item already listed");
        require(nft.ownerOf(itemId) == msg.sender, "You don't own this item");

        // Transfer the NFT to the marketplace contract
        nft.transferFrom(msg.sender, address(this), itemId);

        items[itemId] = Item(msg.sender, price, true, false, 0, 0, 0, address(0));
        emit ItemListed(itemId, msg.sender, price, false);
    }

    function buy(address nftContract, uint256 itemId) external payable {
        IERC721 nft = IERC721(nftContract);
        Item storage item = items[itemId];
        require(item.isForSale, "Item is not for sale");
        require(item.seller != address(0), "Item does not exist");
        require(msg.value >= item.price, "Insufficient funds");

        item.isForSale = false;
        emit ItemSold(itemId, item.seller, msg.sender, item.price);

        // Transfer the NFT back to the buyer
        nft.transferFrom(address(this), msg.sender, itemId);

        (bool success, ) = payable(item.seller).call{value: item.price}("");
        require(success, "Transfer to seller failed");

        if (msg.value > item.price) {
            (success, ) = payable(msg.sender).call{value: msg.value - item.price}("");
            require(success, "Refund failed");
        }
    }

    function startAuction(address nftContract, uint256 itemId, uint256 startTime, uint256 endTime) external {
        IERC721 nft = IERC721(nftContract);
        require(items[itemId].seller == address(0), "Item already listed");
        require(nft.ownerOf(itemId) == msg.sender, "You don't own this item");
        require(startTime < endTime, "Invalid auction period");

        // Transfer the NFT to the marketplace contract
        nft.transferFrom(msg.sender, address(this), itemId);

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
            (bool success, ) = payable(item.highestBidder).call{value: item.highestBid}("");
            require(success, "Refund failed");
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

        // Transfer the NFT to the auction winner
        IERC721 nft = IERC721(item.seller);
        nft.transferFrom(address(this), winner, itemId);

        if (winner != address(0)) {
            (bool success, ) = payable(item.seller).call{value: winningBid}("");
            require(success, "Transfer to seller failed");
        }
    }

    function cancelAuction(uint256 itemId) external {
        Item storage item = items[itemId];
        require(item.isAuction, "Auction is not active");
        require(item.seller == msg.sender, "You are not the seller");
        require(item.highestBidder == address(0), "Bids have been placed");

        item.isAuction = false;
        emit AuctionCancelled(itemId, item.seller);

        // Transfer the NFT back to the seller
        IERC721 nft = IERC721(item.seller);
        nft.transferFrom(address(this), msg.sender, itemId);
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

        // Transfer the NFT back to the seller
        IERC721 nft = IERC721(item.seller);
        nft.transferFrom(address(this), msg.sender, itemId);
    }

    function setMarketplaceOwner(address newOwner) external onlyMarketplaceOwner {
        marketplaceOwner = newOwner;
    }
}