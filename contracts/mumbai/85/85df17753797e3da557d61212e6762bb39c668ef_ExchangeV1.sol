/**
 *Submitted for verification at polygonscan.com on 2022-04-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface NFT {
    function ownerOf(uint256 _tokenId) external view returns (address);
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
}

interface Token {
    function transferFrom(address _from, address _to, uint256 _amount) external;
}

contract ExchangeV1 {
    struct ListItem {
        // address collection;
        // uint256 tokenId;
        address currency;
        uint256 price;
        uint256 startTime;
        uint256 endTime;
    }

    struct ItemBid {
        // address collection;
        // uint256 tokenId;
        address bidder;
        address currency;
        uint256 price;
        uint256 startTime;
        uint256 endTime;
    }

    mapping(address => mapping(uint256 => ListItem)) public listItem;
    mapping(address => mapping(uint256 => ItemBid[])) public itemBids;

    // approve from owner and then list item
    function listItemForSale(address _collection, uint256 _tokenId, ListItem memory _item) external {
        listItem[_collection][_tokenId] = _item;

        // listen for transfer event of this token
        // if done apart from this contract:
        // remove item from sale list in the subgraph
    }

    // take approval from bidder for `bid` amount of bid currency
    function placeBid(address _collection, uint256 _tokenId, ItemBid memory _bid) external {
        require(msg.sender == _bid.bidder);

        itemBids[_collection][_tokenId].push(_bid);
    }

    // take approval from nft owner i.e msg.sender for `tokenId` nft
    function acceptBid(address _collection, uint256 _tokenId, uint256 _index) external {
        ItemBid memory bid = itemBids[_collection][_tokenId][_index];
        NFT nft = NFT(_collection);

        require(block.timestamp >= bid.startTime);
        require(block.timestamp < bid.endTime);

        require(nft.ownerOf(_tokenId) == msg.sender);

        Token(bid.currency).transferFrom(msg.sender, bid.bidder, bid.price);
        nft.transferFrom(msg.sender, bid.bidder, _tokenId);
    }

    function buyItemOnSale(address _collection, uint256 _tokenId) external {
    	ListItem memory item = listItem[_collection][_tokenId];

        require(block.timestamp >= item.startTime);
        require(block.timestamp < item.endTime);

        NFT nft = NFT(_collection);
        Token(item.currency).transferFrom(msg.sender, nft.ownerOf(_tokenId), item.price);

        nft.transferFrom(nft.ownerOf(_tokenId), msg.sender, _tokenId);
    }
}