pragma solidity ^0.8.9;

contract SupplyChain {
    // Roles
    enum Role { CollectionAgency, WasteGenerator, Recycler, Manufacturer }

    // Mapping from address to role
    mapping(address => Role) public roles;

    // Struct for a waste item
    struct WasteItem {
        uint id;
        string material;
        uint quantity;
        Role source;
        Role destination;
        address owner;
    }

    // Array of waste items
    WasteItem[] public wasteItems;

    // Mapping from waste item id to index in wasteItems array
    mapping(uint => uint) public wasteItemIdToIndex;

    // Add a new waste item to the supply chain
    function addWasteItem(uint _id, string memory _material, uint _quantity, Role _source, Role _destination) public {
        // Only waste generators can add waste items
        require(roles[msg.sender] == Role.WasteGenerator, "Sender must be a waste generator");

        wasteItems.push(WasteItem(_id, _material, _quantity, _source, _destination, msg.sender));
        wasteItemIdToIndex[_id] = wasteItems.length - 1;
    }

    // Transfer ownership of a waste item
    function transferWasteItem(uint _id, address _to) public {
        uint index = wasteItemIdToIndex[_id];
        WasteItem storage wasteItem = wasteItems[index];

        // Check that the waste item exists and the sender is the owner
        require(wasteItem.id == _id, "Waste item does not exist");
        require(wasteItem.owner == msg.sender, "Sender is not the owner of the waste item");

        // Transfer ownership
        wasteItem.owner = _to;
    }

    // Update the destination of a waste item
    function updateDestination(uint _id, Role _destination) public {
        uint index = wasteItemIdToIndex[_id];
        WasteItem storage wasteItem = wasteItems[index];

        // Check that the waste item exists and the sender is the owner
        require(wasteItem.id == _id, "Waste item does not exist");
        require(wasteItem.owner == msg.sender, "Sender is not the owner of the waste item");

        // Update the destination
        wasteItem.destination = _destination;
    }

    // Get the details of a waste item
    function getWasteItem(uint _id) public view returns (uint, string memory, uint, Role, Role, address) {
        uint index = wasteItemIdToIndex[_id];
        WasteItem storage wasteItem = wasteItems[index];

        // Check that the waste item exists
        require(wasteItem.id == _id, "Waste item does not exist");

        return (wasteItem.id, wasteItem.material, wasteItem.quantity, wasteItem.source, wasteItem.destination, wasteItem.owner);
    }
}