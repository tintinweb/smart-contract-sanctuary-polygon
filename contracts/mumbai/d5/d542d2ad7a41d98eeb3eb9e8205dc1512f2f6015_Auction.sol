/**
 *Submitted for verification at polygonscan.com on 2022-12-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Auction
 * @dev Seller can place items on sale for fixed price, also can cancel and accept offer.
 * @dev Buyer can purchase item for given by seller price, also can propose his price to seller.
 */
contract Auction {
    /*
    IMPORTANT: unclear what do the items sold on the auction represent
    The intended usage of the contract must be accompanied by backend service
    It should listen to event NewItem, and allow user to describe item details in db
    As well it should listen to event ItemSold, and proceed with the asset delivery 
    */

    event NewItem(uint id);
    event ItemSold(uint id);

    // Structure to store item data
    struct Item {
        bool sold;
        uint price;
        address seller;
        address buyer;
    }

    // Auction item
    Item[] public items;

    // Current item index
    uint public itemsIndex;
    
    /**
     * @dev Constructor
     */
    constructor() {
        itemsIndex = 0;
    }
    
    /**
     * @dev Place item for sale
     * @param _price Item price
     */
    function placeItem(uint _price) public {
        // Create item
        Item memory item;
        item.price = _price;
        item.sold = false;
        item.seller = msg.sender;
        item.buyer = address(0);

        items.push(item);
        
        emit NewItem(itemsIndex);

        // Increment current item index
        itemsIndex++;
    }
    
    /**
     * @dev Buy item by given price
     * @param _itemIndex Item index
     */
    function buyItem(uint _itemIndex) public payable {
        // Retrieve item
        Item storage item = items[_itemIndex];
        
        // Only if not sold
        require(!item.sold, "Item already sold");
        
        // Only if buyer not set
        require(item.buyer == address(0), "Item already bought");
        
        // Buy item
        item.sold = true;
        item.buyer = msg.sender;
   
        emit ItemSold(_itemIndex);
   
        // Transfer ETH from seller to buyer
        require(
            payable(item.seller).send(item.price),
            "Transfer failed"
        );
    }

    struct Offer {
            uint itemId;
            uint price;
            address buyer;
            bool accepted;
    }

    Offer[] public offers;

    /**
     * @dev Make offer
     * @param _itemIndex Item index
     * @param _price Offer price
     */
    function makeOffer(uint _itemIndex, uint _price) public {
        // Retrieve item
        Item storage item = items[_itemIndex];
        
        // Only if not sold
        require(!item.sold, "Item already sold");
        
        Offer memory offer = Offer({
            itemId: _itemIndex,
            price: _price,
            buyer: msg.sender,
            accepted: false
        });
        offers.push(offer);
    }
    
    /**
     * @dev Accept offer
     * @param _offerIndex Offer index
     */
    function acceptOffer(uint _offerIndex) public {
        // Retrieve offer
        Offer storage offer = offers[_offerIndex];
        
        // Only if not accepted yet
        require(!offer.accepted, "Offer is already accepted");
        
        // Retrieve item
        Item storage item = items[offer.itemId];
        
        // Only if not sold
        require(!item.sold, "Item is sold");
        
        // Accept offer
        offer.accepted = true;
      }

    /**
     * @dev Execute offer
     * @dev Once offer accepted by seller, it can be paid by buyer
     * @param _offerIndex Offer index
     */
    function executeOffer(uint _offerIndex) public payable {
        // Retrieve offer
        Offer storage offer = offers[_offerIndex];
        
        // Only if accepted
        require(offer.accepted, "Offer is not accepted yet");
        
        // Retrieve item
        Item storage item = items[offer.itemId];
        
        // Only if not sold
        require(!item.sold, "Item is sold");
        
        // Buy item
        item.sold = true;
        item.buyer = offer.buyer;

        emit ItemSold(offer.itemId);

        // Transfer ETH from seller to buyer
        require(
            payable(item.seller).send(1),
            "Transfer failed"
        );
    }
    
    /**
     * @dev Cancel item
     * @param _itemIndex Item index
     */
    function cancelItem(uint _itemIndex) public {
        // Retrieve item
        Item storage item = items[_itemIndex];
        
        // Only if not sold
        require(!item.sold, "Item is sold");
        
        // Cancel item
        delete items[_itemIndex];
    }
}