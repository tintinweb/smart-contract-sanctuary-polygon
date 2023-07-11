/**
 *Submitted for verification at polygonscan.com on 2023-07-11
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

contract summa {
    enum ListingType { Auction, DirectSale }

    struct Listing {
        uint256 tokenId;
        address payable seller;
        uint256 price;
        bool active;
        address highestBidder;
        uint256 highestBid;
        ListingType listingType; // New field to specify the listing type
    }

    mapping(address => mapping(uint256 => Listing)) public listings;

    modifier onlyActiveListing(address nftContract, uint256 tokenId) {
        require(listings[nftContract][tokenId].active, "Listing not found or inactive");
        _;
    }

    function createListing(address nftContract, uint256[] calldata tokenIds, uint256[] calldata prices, ListingType listingType) external {
        IERC721 nft = IERC721(nftContract);
        require(tokenIds.length == prices.length, "Invalid input arrays");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 price = prices[i];

            require(nft.ownerOf(tokenId) == msg.sender, "Only NFT owner can create listing");
            require(nft.getApproved(tokenId) == address(this) || nft.isApprovedForAll(nft.ownerOf(tokenId), address(this)), "Marketplace contract must be approved");
            listings[nftContract][tokenId] = Listing(tokenId, payable(msg.sender), price, true, address(0), 0, listingType); // Explicitly convert msg.sender to address payable            
        }
    }


    function cancelListing(address nftContract, uint256 tokenId) external onlyActiveListing(nftContract, tokenId) {
        Listing storage listing = listings[nftContract][tokenId];
        require(listing.seller == msg.sender, "Only seller can cancel listing");

        // Refund the highest bid if exists
        if (listing.highestBidder != address(0)) {
            payable(listing.highestBidder).transfer(listing.highestBid);
        }

        delete listings[nftContract][tokenId];
    }

    function placeBid(address nftContract, uint256 tokenId) external payable onlyActiveListing(nftContract, tokenId) {
        Listing storage listing = listings[nftContract][tokenId];
        require(msg.sender != listing.seller, "Seller cannot place a bid");
        require(msg.value > 0, "Bid value must be greater than zero");
        require(listing.listingType == ListingType.Auction, "Bidding is not allowed for this listing");

        // Refund the previous highest bidder
        if (listing.highestBidder != address(0)) {
            payable(listing.highestBidder).transfer(listing.highestBid);
        }

        listing.highestBidder = msg.sender;
        listing.highestBid = msg.value;
    }

    function acceptBid(address nftContract, uint256 tokenId) external onlyActiveListing(nftContract, tokenId) {
        Listing storage listing = listings[nftContract][tokenId];
        require(msg.sender == listing.seller, "Only seller can accept the bid");
        require(listing.highestBidder != address(0), "No bid has been placed");
        require(listing.listingType == ListingType.Auction, "This listing is not an auction");

        address highestBidder = listing.highestBidder;
        uint256 highestBid = listing.highestBid;

        // Transfer the NFT to the highest bidder
        IERC721(nftContract).safeTransferFrom(listing.seller, highestBidder, tokenId);

        // Pay the seller the bid amount
        payable(listing.seller).transfer(highestBid);

        // Remove the listing
        delete listings[nftContract][tokenId];
    }

    event LogValue(string message, uint256 value);

    function buyDirect(address nftContract, uint256[] calldata tokenIds) external payable {
        IERC721 nft = IERC721(nftContract);

        uint256 totalPrice = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            Listing storage listing = listings[nftContract][tokenId];

            require(msg.sender != listing.seller, "Seller cannot buy their own NFT");
            totalPrice += listing.price;
        }

        emit LogValue("msg.value", msg.value);
        emit LogValue("totalPrice", totalPrice);

        require(msg.value >= totalPrice / 1 ether, "Insufficient funds to buy the NFTs");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            Listing storage listing = listings[nftContract][tokenId];

            // Transfer the NFT to the buyer
            nft.safeTransferFrom(listing.seller, msg.sender, tokenId);

            // Pay the seller the sale amount
            listing.seller.transfer(listing.price);

            // Remove the listing
            delete listings[nftContract][tokenId];
        }
    }



    // Implement the remaining functions from the IERC721 interface
    function balanceOf(address nftContract, address owner) external view returns (uint256) {
        return IERC721(nftContract).balanceOf(owner);
    }

    function ownerOf(address nftContract, uint256 tokenId) external view returns (address) {
        address tokenOwner = IERC721(nftContract).ownerOf(tokenId);
        require(tokenOwner != address(0), "Token does not exist");
        return tokenOwner;
    }

    function safeTransferFrom(address nftContract, address from, address to, uint256 tokenId) external {
        IERC721(nftContract).safeTransferFrom(from, to, tokenId);
    }

    function transferFrom(address nftContract, address from, address to, uint256 tokenId) external {
        IERC721(nftContract).transferFrom(from, to, tokenId);
    }

    function approve(address nftContract, address to, uint256 tokenId) external {
        IERC721(nftContract).approve(to, tokenId);
    }

    function getApproved(address nftContract, uint256 tokenId) external view returns (address) {
        return IERC721(nftContract).getApproved(tokenId);
    }

    function setApprovalForAll(address nftContract, address operator, bool approved) external {
        IERC721(nftContract).setApprovalForAll(operator, approved);
    }

    function isApprovedForAll(address nftContract, address owner, address operator) external view returns (bool) {
        return IERC721(nftContract).isApprovedForAll(owner, operator);
    }
}