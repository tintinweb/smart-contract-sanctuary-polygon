// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract InstiShop {
    struct Item {
        string name;
        string description;
        string media;
        string location;
        uint256 buyPrice;
        uint256 rentPricePerDay;
        address owner;
        uint256 validTill;
        address renter;
    }

    uint256 itemCount;
    mapping(uint256 => Item) public idToItem;

    event ItemAdded(address indexed owner, uint256 indexed id);
    event ItemOwnershipTransferred(address indexed owner, uint256 indexed id);

    function addItem(
        string memory name,
        string memory description,
        string memory media,
        string memory location,
        uint256 rentPricePerDay,
        uint256 buyPrice
    ) external {
        Item memory item = Item(
            name,
            description,
            media,
            location,
            buyPrice,
            rentPricePerDay,
            msg.sender,
            0,
            address(0)
        );
        itemCount++;
        idToItem[itemCount] = item;
        emit ItemAdded(msg.sender, itemCount);
    }

    function rentItem(uint256 id, uint256 daysToRent) external payable {
        require(id < itemCount, "Rental: Item does not exist");
        Item storage item = idToItem[id];
        require(
            item.owner != msg.sender,
            "Rental: You cannot rent your own item"
        );
        require(item.renter == address(0), "Rental: Item is already rented");
        require(
            msg.value == item.rentPricePerDay * daysToRent,
            "Rental: Incorrect payment amount"
        );
        item.renter = msg.sender;
        item.validTill = block.timestamp + daysToRent * 1 days;
        emit ItemOwnershipTransferred(msg.sender, id);
    }

    function returnItem(uint256 id) external {
        require(id < itemCount, "Rental: Item does not exist");
        Item storage item = idToItem[id];
        require(
            item.renter == msg.sender,
            "Rental: You cannot return an item you do not own"
        );
        require(
            block.timestamp > item.validTill,
            "Rental: Item is not yet due for return"
        );
        item.renter = address(0);
        item.validTill = 0;
        emit ItemOwnershipTransferred(item.owner, id);
    }

    function buyItem(uint256 id) external payable {
        require(id < itemCount, "Rental: Item does not exist");
        Item storage item = idToItem[id];
        require(
            item.owner != msg.sender,
            "Rental: You cannot buy your own item"
        );
        require(item.renter == address(0), "Rental: Item is already rented");
        require(msg.value == item.buyPrice, "Rental: Incorrect payment amount");
        item.owner = msg.sender;
        emit ItemOwnershipTransferred(msg.sender, id);
    }

    function getItems() external view returns (Item[] memory) {
        Item[] memory items = new Item[](itemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            items[i] = idToItem[i + 1];
        }
        return items;
    }

    function getItemsByOwner(address owner)
        external
        view
        returns (Item[] memory)
    {
        Item[] memory items = new Item[](itemCount);
        uint256 count;
        for (uint256 i = 0; i < itemCount; i++) {
            if (idToItem[i + 1].owner == owner) {
                items[count] = idToItem[i + 1];
                count++;
            }
        }
        Item[] memory itemsByOwner = new Item[](count);
        for (uint256 i = 0; i < count; i++) {
            itemsByOwner[i] = items[i];
        }
        return itemsByOwner;
    }

    function getItemsByRenter(address renter)
        external
        view
        returns (Item[] memory)
    {
        Item[] memory items = new Item[](itemCount);
        uint256 count;
        for (uint256 i = 0; i < itemCount; i++) {
            if (idToItem[i + 1].renter == renter) {
                items[count] = idToItem[i + 1];
                count++;
            }
        }
        Item[] memory itemsByRenter = new Item[](count);
        for (uint256 i = 0; i < count; i++) {
            itemsByRenter[i] = items[i];
        }
        return itemsByRenter;
    }
}