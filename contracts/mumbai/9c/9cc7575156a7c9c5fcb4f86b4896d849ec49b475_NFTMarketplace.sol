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
contract NFTMarketplace {
    struct Listing {
        uint256 tokenId;
        address seller;
        uint256 price;
        bool active;
    }

    mapping(uint256 => Listing) public listings;

    modifier onlyActiveListing(uint256 tokenId) {
        require(listings[tokenId].active, "Listing not found or inactive");
        _;
    }

    function createListing(address nftContract, uint256 tokenId, uint256 price) external {
        IERC721 nft = IERC721(nftContract);
        require(nft.ownerOf(tokenId) == msg.sender, "Only NFT owner can create listing");
        require(nft.getApproved(tokenId) == address(this), "Marketplace contract must be approved");

        listings[tokenId] = Listing(tokenId, msg.sender, price, true);
    }

    function cancelListing(uint256 tokenId) external onlyActiveListing(tokenId) {
        require(listings[tokenId].seller == msg.sender, "Only seller can cancel listing");
        delete listings[tokenId];
    }

    function makeOffer(address nftContract, uint256 tokenId) external payable onlyActiveListing(tokenId) {
        Listing storage listing = listings[tokenId];
        require(msg.value >= listing.price, "Insufficient payment for the listing");

        IERC721(nftContract).safeTransferFrom(listing.seller, msg.sender, tokenId);

        payable(listing.seller).transfer(listing.price);

        delete listings[tokenId];
    }
}