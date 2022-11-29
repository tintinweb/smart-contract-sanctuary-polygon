// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Types.sol";

/**
 * @title Items
 * @author TEAM201
 * @dev A Library for items management
 */

contract Items {
    Types.Item[] internal items;
    mapping(string => Types.Item) internal item;
    mapping(address => string[]) internal accountLinkedItems;
    mapping(string => Types.ItemHistory) internal itemHistory;

    // The Events

    event NewItem(
        string name,
        string manufacturerName,
        string barcodeId,
        uint256 manufacturedDate,
        uint256 expiringDate
    );
    event ItemOwnershipTransfer(
        string name,
        string manufacturerName,
        string barcodeId,
        string buyerName,
        string buyerEmail
    );

    // MODIFIERS

    // Check if item already exists
    modifier itemExists(string memory Id) {
        require(!compareStrings(item[Id].barcodeId, ""));
        _;
    }

    // Check if item does not exists
    modifier itemNotExists(string memory Id) {
        require(compareStrings(item[Id].barcodeId, ""));
        _;
    }

    // SPECIAL FUNCTIONS

    // compare string operatins, this function is a little expensive to run
    function compareStrings(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    // remove item from current list one sold i.e transferring the ownership
    function transferOwnership(
        address sellerId,
        address buyerId,
        string memory itemId
    ) internal {
        accountLinkedItems[buyerId].push(itemId);
        string[] memory sellerItems_ = accountLinkedItems[sellerId];
        uint256 matchIndex_ = (sellerItems_.length + 1);
        for (uint256 i = 0; i < sellerItems_.length; i++) {
            if (compareStrings(sellerItems_[i], itemId)) {
                matchIndex_ = i;
                break;
            }
        }
        assert(matchIndex_ < sellerItems_.length); // Match found
        if (sellerItems_.length == 1) {
            delete accountLinkedItems[sellerId];
        } else {
            accountLinkedItems[sellerId][matchIndex_] = accountLinkedItems[
                sellerId
            ][sellerItems_.length - 1];
            delete accountLinkedItems[sellerId][sellerItems_.length - 1];
            accountLinkedItems[sellerId].pop();
        }
    }

    // OTHER FUNCTIONS

    // get all item list linked to an account
    function getAccountItems() internal view returns (Types.Item[] memory) {
        string[] memory _id = accountLinkedItems[msg.sender];
        Types.Item[] memory _item = new Types.Item[](_id.length);
        for (uint256 i = 0; i < _id.length; i++) {
            _item[i] = item[_id[i]];
        }
        return _item;
    }

    // get specific item linked to an account
    function getSpecificItem(string memory barcodeId)
        internal
        view
        returns (Types.Item memory, Types.ItemHistory memory)
    {
        return (item[barcodeId], itemHistory[barcodeId]);
    }

    // Add new item to the item list
    function addItem(Types.Item memory _item, uint256 currentTime_)
        internal
        itemNotExists(_item.barcodeId)
    {
        require(_item.manufacturer == msg.sender, "Only manufacturer can add");
        items.push(_item);
        item[_item.barcodeId] = _item;
        itemHistory[_item.barcodeId].manufacturer = Types.AccountTransactions({
            transactionAddress: msg.sender,
            timestamp: currentTime_
        });
        accountLinkedItems[msg.sender].push(_item.barcodeId);
        emit NewItem(
            _item.name,
            _item.manufacturerName,
            _item.barcodeId,
            _item.manufacturedDate,
            _item.expiringDate
        );
    }

    // Sell item i.e transfer the ownership to another user/account
    function sell(
        address partyId,
        string memory barcodeId,
        Types.AccountDetails memory _party,
        uint256 currentTime_
    ) internal itemExists(barcodeId) {
        Types.Item memory _item = item[barcodeId];

        // Update to history of an item
        Types.AccountTransactions memory AccountTransactions_ = Types
            .AccountTransactions({
                transactionAddress: _party.accountId,
                timestamp: currentTime_
            });
        if (Types.AccountRole(_party.role) == Types.AccountRole.Distributor) {
            itemHistory[barcodeId].distributor = AccountTransactions_;
        } else if (
            Types.AccountRole(_party.role) == Types.AccountRole.Retailer
        ) {
            itemHistory[barcodeId].retailer = AccountTransactions_;
        } else if (
            Types.AccountRole(_party.role) == Types.AccountRole.Customer
        ) {
            itemHistory[barcodeId].customers.push(AccountTransactions_);
        } else {
            // Outside the scope of this work
            revert("Not valid operation");
        }
        transferOwnership(msg.sender, partyId, barcodeId); // Transfer of ownership between accounts 

        // Emit event
        emit ItemOwnershipTransfer(
            _item.name,
            _item.manufacturerName,
            _item.barcodeId,
            _party.name,
            _party.email
        );
    }
} // END OF CONTRACT

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**
 * @title Types
 * @author TEAM201
 * @dev The Program's Custom types
 */

library Types {
    // ENUMS

    // These are the roles available for the users of the platform

    enum AccountRole {
        Manufacturer,
        Distributor,
        Retailer,
        Customer
    }


    // Groups of items supplied by a manufacturer

    enum ItemType {
        Antibiotics, 
        Antimalaria,
        Analgestics,
        Supplements,
        Steroids

    }
    

    // STRUCT

    // this contains account details of the users of the platform  
    struct AccountDetails {
        AccountRole role;
        address accountId;
        string name;
        string email;
    } 

    // this contains the transcation details of the user
    struct AccountTransactions {
        address transactionAddress; // account Address of the user
        uint timestamp; // time of purchase
    }

    struct ItemHistory {
        AccountTransactions manufacturer;
        AccountTransactions distributor;
        AccountTransactions retailer;
        AccountTransactions[] customers; //Array of customers transaction
     
    }

    struct Item {
        string name;
        string manufacturerName;
        address manufacturer;
        uint256 manufacturedDate;
        uint256 expiringDate;
        bool isInBatch; // this is true if the items is sold in batches
        uint256 batchCount; // Items that were packed in single batch
        string barcodeId;
        string itemImage;
        ItemType itemType;
        string usage;
        string[] others; // Other information to share
    }
}