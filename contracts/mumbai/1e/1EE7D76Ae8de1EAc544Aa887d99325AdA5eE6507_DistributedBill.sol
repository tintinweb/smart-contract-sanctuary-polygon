// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract DistributedBill {

    uint256 public billCounter = 0;

    struct SingleBill {
        uint256 billId;
        address seller;
        address buyer;
        string shippingAddress;
        string originAddress;
        uint256 dateCreated;
        bool isPaid;
        uint256[] inventoryIDs;
    }

    mapping (address => uint256) public sellertoBillId;
    mapping (address => uint256) public buyertoBillId;
    mapping (uint256 => SingleBill) public billIdtoBill;

    event InventoryUpdated(
    address updatedBy,
    uint256[] inventory
  );

  event MagicMessage( string message);
  event PaymentToggle(bool isPaid);
  event ShippingUpdated(string shippingAddress);

    function getSellerInventoryIds(address _sellerAddress) external view returns (uint256[] memory) {
        uint256 currentId = sellertoBillId[_sellerAddress];
        return billIdtoBill[currentId].inventoryIDs;
    }

    function getBuyerInventoryIds(address _buyerAddress) external view returns (uint256[] memory) {
        uint256 currentId = buyertoBillId[_buyerAddress];
        return billIdtoBill[currentId].inventoryIDs;
    }

    function createBill(
        address _sellerAddress, 
        string memory shippingAddress,
        string memory originAddress,
        uint256[] memory inventoryIds 
        ) external returns (uint256[] memory){
        billCounter += 1;
        billIdtoBill[billCounter] = SingleBill(
            billCounter, _sellerAddress, 
            msg.sender, shippingAddress,
            originAddress, 
            block.timestamp, 
            false, 
            inventoryIds);
        buyertoBillId[msg.sender] = billCounter;
        sellertoBillId[_sellerAddress] = billCounter;
        emit MagicMessage("This is where the magic happens");
        return inventoryIds;
    }

    function updateInventory(address _sellerAddress, uint256[] memory _newInventoryIds) external returns (uint256[] memory) {
        uint256 currentId = sellertoBillId[_sellerAddress];
        require(billIdtoBill[currentId].isPaid == false, "Cannot update after buyer has paid");
        billIdtoBill[currentId].inventoryIDs = _newInventoryIds;
        emit InventoryUpdated(msg.sender, _newInventoryIds);
        emit MagicMessage("In honor of Big P");
        return _newInventoryIds;
    }

    function updateShippingAddress(address _sellerAddress, string memory newAddress) external returns(string memory) {
        uint256 currentId = sellertoBillId[_sellerAddress];
        require(billIdtoBill[currentId].isPaid == false, "Cannot update after buyer has paid");
        billIdtoBill[currentId].shippingAddress = newAddress;
        emit ShippingUpdated(newAddress);
        emit MagicMessage("Lets distribute the logistics");
        return newAddress;
    }

    function updatePaid(address _buyerAddress ,bool _isPaid) external returns(bool) {
        uint256 currentId = buyertoBillId[_buyerAddress];
        billIdtoBill[currentId].isPaid = _isPaid;
        emit PaymentToggle(_isPaid);
        emit MagicMessage("ChaChing");
        return _isPaid;
    }

}