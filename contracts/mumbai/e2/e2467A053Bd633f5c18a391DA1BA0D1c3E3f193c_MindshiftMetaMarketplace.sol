// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @custom:security-contact [email protected]
contract MindshiftMetaMarketplace {
    enum ListingStatus {
        ACTIVE,
        SOLD,
        CANCELED
    }

    enum ListingType {
        BUY_NOW,
        AUCTION
    }

    enum ItemType {
        CRYPTO,
        NFT
    }

    enum ConsiderationType {
        ALL,
        CHOICE
    }

    struct Item {
        uint256 itemType;
        address token;
        uint256 identifierOrCriteria;
        uint256 startAmount;
        uint256 endAmount;
        address recipient;
    }

    struct Listing {
        ListingStatus status;
        uint256 listingType;
        address offerer;
        mapping(uint256 => Item) offer;
        uint256 considerationType;
        mapping(uint256 => Item) consideration;
    }

    constructor() {}

    uint256 private _listingId = 0;
    mapping(uint256 => Listing) private _listings;

    function createListing(
        uint256 _listingType,
        Item[] calldata _offer,
        uint256 _considerationType,
        Item[] calldata _consideration
    ) external {
        Listing storage _listing = _listings[_listingId];

        _listing.status = ListingStatus.ACTIVE;
        _listing.listingType = _listingType;
        _listing.offerer = msg.sender;

        for (uint256 i = 0; i < _offer.length; i++) {
            _listing.offer[i].itemType = _offer[i].itemType;
            _listing.offer[i].token = _offer[i].token;
            _listing.offer[i].identifierOrCriteria = _offer[i]
                .identifierOrCriteria;
            _listing.offer[i].startAmount = _offer[i].startAmount;
            _listing.offer[i].endAmount = _offer[i].endAmount;
            _listing.offer[i].recipient = _offer[i].recipient;
        }

        _listing.considerationType = _considerationType;

        for (uint256 i = 0; i < _consideration.length; i++) {
            _listing.consideration[i].itemType = _consideration[i].itemType;
            _listing.consideration[i].token = _consideration[i].token;
            _listing.consideration[i].identifierOrCriteria = _consideration[i]
                .identifierOrCriteria;
            _listing.consideration[i].startAmount = _consideration[i]
                .startAmount;
            _listing.consideration[i].endAmount = _consideration[i].endAmount;
            _listing.consideration[i].recipient = _consideration[i].recipient;
        }

        _listingId++;
    }

    function getListing(uint256 listingId) public view returns (Item memory) {
        return _listings[listingId].offer[0];
    }
}