/**
 *Submitted for verification at polygonscan.com on 2023-07-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

contract NFTMarketplace is IERC721 {
    struct Listing {
        uint256 tokenId;
        address seller;
        uint256 price;
        bool active;
        address highestBidder;
        uint256 highestBid;
    }

    mapping(uint256 => Listing) public listings;

    modifier onlyActiveListing(uint256 tokenId) {
        require(listings[tokenId].active, "Listing not found or inactive");
        _;
    }
    
    address public nftContract;

    constructor(address _nftContract) {
        nftContract = _nftContract;
    }

    function createListing(uint256 tokenId, uint256 price) external {
        IERC721 nft = IERC721(nftContract);
        require(nft.ownerOf(tokenId) == msg.sender, "Only NFT owner can create listing");
        require(nft.getApproved(tokenId) == address(this), "Marketplace contract must be approved");

        listings[tokenId] = Listing(tokenId, msg.sender, price, true, address(0), 0);
    }

    function cancelListing(uint256 tokenId) external onlyActiveListing(tokenId) {
        Listing storage listing = listings[tokenId];
        require(listing.seller == msg.sender, "Only seller can cancel listing");

        // Refund the highest bid if exists
        if (listing.highestBidder != address(0)) {
            payable(listing.highestBidder).transfer(listing.highestBid);
        }

        delete listings[tokenId];
    }

    function placeBid(uint256 tokenId) external payable onlyActiveListing(tokenId) {
        Listing storage listing = listings[tokenId];
        require(msg.sender != listing.seller, "Seller cannot place a bid");
        require(msg.value > 0, "Bid value must be greater than zero");

        // Refund the previous highest bidder
        if (listing.highestBidder != address(0)) {
            payable(listing.highestBidder).transfer(listing.highestBid);
        }

        listing.highestBidder = msg.sender;
        listing.highestBid = msg.value;
    }

    function acceptBid(uint256 tokenId) external onlyActiveListing(tokenId) {
        Listing storage listing = listings[tokenId];
        require(msg.sender == listing.seller, "Only seller can accept the bid");
        require(listing.highestBidder != address(0), "No bid has been placed");

        address highestBidder = listing.highestBidder;
        uint256 highestBid = listing.highestBid;

        // Transfer the NFT to the highest bidder
        IERC721(nftContract).safeTransferFrom(listing.seller, highestBidder, tokenId);

        // Pay the seller the bid amount
        payable(listing.seller).transfer(highestBid);

        // Remove the listing
        delete listings[tokenId];
    }

    // Implement the remaining functions from the IERC721 interface
    function balanceOf(address owner) external view override returns (uint256) {
        return IERC721(nftContract).balanceOf(owner);
    }

    function ownerOf(uint256 tokenId) external view override returns (address) {
        address tokenOwner = IERC721(nftContract).ownerOf(tokenId);
        require(tokenOwner != address(0), "Token does not exist");
        return tokenOwner;
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external override {
        IERC721(nftContract).safeTransferFrom(from, to, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) external override {
        IERC721(nftContract).transferFrom(from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) external override {
        IERC721(nftContract).approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) external view override returns (address) {
        return IERC721(nftContract).getApproved(tokenId);
    }

    function setApprovalForAll(address operator, bool approved) external override {
        IERC721(nftContract).setApprovalForAll(operator, approved);
    }

    function isApprovedForAll(address owner, address operator) external view override returns (bool) {
        return IERC721(nftContract).isApprovedForAll(owner, operator);
    }
}