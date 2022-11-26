// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract InstiShop {
    struct Item {
        uint256 id;
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

    Item[] public items;

    event ItemAdded(address indexed owner, uint256 indexed id);
    event ItemOwnershipTransferred(address indexed owner, uint256 indexed id);

    modifier validId(uint256 id) {
        require(id < items.length, "InstiShop: Item does not exist");
        _;
    }

    function addItem(
        string memory name,
        string memory description,
        string memory media,
        string memory location,
        uint256 rentPricePerDay,
        uint256 buyPrice
    ) external {
        Item memory item = Item(
            items.length,
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
        items.push(item);
        emit ItemAdded(msg.sender, item.id);
    }

    function rentItem(uint256 id, uint256 daysToRent)
        external
        payable
        validId(id)
    {
        Item storage item = items[id];
        require(
            item.owner != msg.sender,
            "InstiShop: You cannot rent your own item"
        );
        require(item.renter == address(0), "InstiShop: Item is already rented");
        require(
            msg.value == item.rentPricePerDay * daysToRent,
            "InstiShop: Incorrect payment amount"
        );
        item.renter = msg.sender;
        item.validTill = block.timestamp + daysToRent * 1 days;
        payable(item.owner).transfer(msg.value);
        emit ItemOwnershipTransferred(msg.sender, id);
    }

    function returnItem(uint256 id) external validId(id) {
        Item storage item = items[id];
        require(
            item.renter == msg.sender,
            "InstiShop: You cannot return an item you do not own"
        );
        require(
            block.timestamp > item.validTill,
            "InstiShop: Item is not yet due for return"
        );
        item.renter = address(0);
        item.validTill = 0;
        emit ItemOwnershipTransferred(item.owner, id);
    }

    function buyItem(uint256 id) external payable validId(id) {
        Item storage item = items[id];
        require(
            item.owner != msg.sender,
            "InstiShop: You cannot buy your own item"
        );
        require(item.renter == address(0), "InstiShop: Item is already rented");
        require(
            msg.value == item.buyPrice,
            "InstiShop: Incorrect payment amount"
        );
        item.owner = msg.sender;
        payable(item.owner).transfer(msg.value);
        emit ItemOwnershipTransferred(msg.sender, id);
    }

    function getItems() external view returns (Item[] memory) {
        return items;
    }

    function getItemsByOwner(address owner)
        external
        view
        returns (Item[] memory ownerItems)
    {
        Item[] memory ownerItemsTemp = new Item[](items.length);
        uint256 count = 0;
        for (uint256 i = 0; i < items.length; i++) {
            if (items[i].owner == owner) {
                ownerItemsTemp[count] = items[i];
                count++;
            }
        }

        ownerItems = new Item[](count);
        for (uint256 i = 0; i < count; i++) {
            ownerItems[i] = ownerItems[i];
        }
    }

    function getItemsByRenter(address renter)
        external
        view
        returns (Item[] memory renterItems)
    {
        Item[] memory renterItemsTemp = new Item[](items.length);
        uint256 count = 0;
        for (uint256 i = 0; i < items.length; i++) {
            if (items[i].renter == renter) {
                renterItemsTemp[count] = items[i];
                count++;
            }
        }

        renterItems = new Item[](count);
        for (uint256 i = 0; i < count; i++) {
            renterItems[i] = renterItems[i];
        }
    }
}