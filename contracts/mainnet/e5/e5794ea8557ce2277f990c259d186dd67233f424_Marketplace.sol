/**
 *Submitted for verification at polygonscan.com on 2023-05-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Интерфейс ERC721
interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address approved);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

// Контракт Marketplace
contract Marketplace {
    struct Item {
        address seller;
        uint256 price;
        bool isForSale;
    }

    mapping(uint256 => Item) public items;
    address public marketplaceOwner;

    event ItemListed(uint256 indexed itemId, address indexed seller, uint256 price);
    event ItemSold(uint256 indexed itemId, address indexed seller, address indexed buyer, uint256 price);

    modifier onlyMarketplaceOwner() {
        require(msg.sender == marketplaceOwner, "Only marketplace owner can call this function");
        _;
    }

    constructor() {
        marketplaceOwner = msg.sender;
    }

    function listForSale(address nftContract, uint256 itemId, uint256 price) external {
        require(items[itemId].seller == address(0), "Item already listed");

        IERC721 nft = IERC721(nftContract);
        address owner = nft.ownerOf(itemId);
        require(owner == msg.sender, "You don't own this item");

        // Approve the marketplace contract to transfer the NFT
        nft.approve(address(this), itemId);

        items[itemId] = Item(owner, price, true);
        emit ItemListed(itemId, owner, price);
    }

    function buy(address nftContract, uint256 itemId) external payable {
        Item storage item = items[itemId];
        require(item.isForSale, "Item is not for sale");
        require(item.seller != address(0), "Item does not exist");
        require(msg.value >= item.price, "Insufficient funds");

        address seller = item.seller;
        uint256 price = item.price;

        item.isForSale = false;
        emit ItemSold(itemId, seller, msg.sender, price);

        // Transfer the NFT to the buyer
        IERC721 nft = IERC721(nftContract);
        nft.transferFrom(seller, msg.sender, itemId);

        (bool success, ) = payable(seller).call{value: price}("");
        require(success, "Transfer to seller failed");

        if (msg.value > price) {
            (success, ) = payable(msg.sender).call{value: msg.value - price}("");
            require(success, "Refund failed");
        }

        // Refund excess gas fee
        uint256 gasUsed = gasleft();
        uint256 gasPrice = tx.gasprice;
        (success, ) = payable(msg.sender).call{value: gasUsed * gasPrice}("");
        require(success, "Gas fee refund failed");
    }

    function cancelSale(uint256 itemId) external {
        Item storage item = items[itemId];
        require(item.seller == msg.sender, "You are not the seller");

        item.isForSale = false;
    }

    function setMarketplaceOwner(address newOwner) external onlyMarketplaceOwner {
        marketplaceOwner = newOwner;
    }
}