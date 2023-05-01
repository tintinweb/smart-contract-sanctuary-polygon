// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Bill {
    address public seller;
    address public buyer;
    string public  shippingAddress;
    string public originAddress;
    uint256 public  dateCreated;
    bool public isPaid;
    uint256[] public inventoryIDs;

    constructor( 
        address _seller, 
        address _buyer, 
        string memory _shippingAddress, 
        string memory _originAddress,
        uint256[] memory _inventoryIDs
        ) {
        seller = _seller;
        buyer = _buyer;
        shippingAddress = _shippingAddress;
        originAddress = _originAddress;
        inventoryIDs = _inventoryIDs;
        dateCreated = block.timestamp;
        emit MagicMessage("This is where the magic happens");
    }

    modifier authCheck() {
    if(isPaid == true) {
        require(isPaid == true, "Contract is paid in full, changes can no longer be made on this contract");
    }
    if(isPaid == false) {
        require(msg.sender == seller, "Only the seller is authorized to modify the contract at this moment.");
    }
    _;
  }

    event InventoryUpdated(
    address updatedBy,
    uint256[] inventory
  );

  event MagicMessage( string message);
  event PaymentToggle(bool isPaid);
  event ShippingUpdated(string shippingAddress);

    function getInventoryIds() external view returns (uint256[] memory) {
        return inventoryIDs;
    }

    function updateInventoryIds(uint256[] memory _newInventoryIds) external authCheck returns (uint256[] memory) {
        inventoryIDs = _newInventoryIds;
        emit InventoryUpdated(msg.sender, _newInventoryIds);
        emit MagicMessage("In honor of Big P");
        return inventoryIDs;
    }

    function updateShippingAddress(string memory _newAddress) external authCheck returns(string memory) {
        shippingAddress = _newAddress;
        emit ShippingUpdated(_newAddress);
        emit MagicMessage("Lets distribute the logistics");
        return shippingAddress;
    }

    function updatePaid(bool _ispaid) external returns(bool) {
        isPaid = _ispaid;
        emit PaymentToggle(_ispaid);
        emit MagicMessage("ChaChing");
        return isPaid;
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import { Bill } from "./Bill.sol";

contract BillFactory {
  Bill[] public bills;

  event BillCreated(
    address indexed creator,
    address billAddress
  );

  function createBill(
    address _buyer, 
    string memory _shippingAddress,
    string memory _originAddress, 
    uint256[] memory _inventoryIDs) 
    external returns (address) {
      Bill newBill = new Bill(msg.sender, _buyer, _shippingAddress, _originAddress, _inventoryIDs);
      bills.push(newBill);
      emit BillCreated(msg.sender, address(newBill));
      return address(newBill);
  }

  function getBills() external view returns (Bill[] memory) {
    return bills;
  }

}