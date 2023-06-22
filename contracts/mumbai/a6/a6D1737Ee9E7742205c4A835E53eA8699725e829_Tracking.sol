// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Tracking {
    enum ShipmentStatus {
        PENDING,
        IN_TRANSIT,
        DELIVERED
    }

    struct Shipment {
        address sender;
        address receiver;
        uint256 pickupTime;
        uint256 deliveryTime;
        uint256 distance;
        uint256 price;
        ShipmentStatus status;
        bool isPaid;
        string productId;
    }


    // sender is the product owner ;
    //reciever is the the msg.sender who initiates the function of create shipment ; 
    mapping(address => Shipment[]) public shipments;
    uint256 public shipmentCount;

    event ShipmentCreated(address indexed sender, address indexed receiver, uint256 pickupTime, uint256 distance, uint256 price);
    event ShipmentInTransit(address indexed sender, address indexed receiver, uint256 pickupTime);
    event ShipmentDelivered(address indexed sender, address indexed receiver, uint256 deliveryTime);
    event ShipmentPaid(address indexed sender, address indexed receiver, uint256 amount);

    constructor() {
        shipmentCount = 0;
    }
    function createShipment(address sender , address _receiver, uint256 _pickupTime, uint256 _distance, uint256 _price, string memory _productId) public payable {
  require(msg.value == _price, "Payment amount must match the price.");

  Shipment memory shipment = Shipment(sender , msg.sender, _pickupTime, 0, _distance, _price, ShipmentStatus.PENDING, false, _productId);

  shipments[msg.sender].push(shipment);
  shipmentCount++;

  emit ShipmentCreated(sender, _receiver, _pickupTime, _distance, _price);
}
    function startShipment(address _sender, address _receiver, uint256 _index) public {
        Shipment storage shipment = shipments[_sender][_index];

        require(shipment.receiver == _receiver, "Invalid receiver.");
        require(shipment.status == ShipmentStatus.PENDING, "Shipment already in transit.");

        shipment.status = ShipmentStatus.IN_TRANSIT;

        emit ShipmentInTransit(_sender, _receiver, shipment.pickupTime);
    }

    function completeShipment(address _sender, address _receiver, uint256 _index) public {
        Shipment storage shipment = shipments[_sender][_index];

        require(shipment.receiver == _receiver, "Invalid receiver.");
        require(shipment.status == ShipmentStatus.IN_TRANSIT, "Shipment already in transit.");
        require(!shipment.isPaid, "Shipment already paid.");

        shipment.status = ShipmentStatus.DELIVERED;
        shipment.deliveryTime = block.timestamp;

        uint256 amount = shipment.price;
        payable(shipment.sender).transfer(amount);

        shipment.isPaid = true;

        emit ShipmentDelivered(_sender, _receiver, shipment.deliveryTime);
        emit ShipmentPaid(_sender, _receiver, amount);
    }

    // function getShipment(address _sender, uint256 _index) public view returns (address, address, uint256, uint256, uint256, uint256, ShipmentStatus, bool, uint256) {
    //     Shipment memory shipment = shipments[_sender][_index];
    //     return (shipment.sender, shipment.receiver, shipment.pickupTime, shipment.deliveryTime, shipment.distance, shipment.price, shipment.status, shipment.isPaid, shipment.productId);
    // }

    // function getShipmentsCount(address _sender) public view returns (uint256) {
    //     return shipments[_sender].length;
    // }

    // function getShipmentsByProductId(address _sender, uint256 _productId) public view returns (Shipment[] memory) {
    //     Shipment[] storage allShipments = shipments[_sender];
    //     Shipment[] memory filteredShipments = new Shipment[](allShipments.length);
    //     uint256 filteredCount = 0;

    //     for (uint256 i = 0; i < allShipments.length; i++) {
    //         if (allShipments[i].productId == _productId) {
    //             filteredShipments[filteredCount] = allShipments[i];
    //             filteredCount++;
    //         }
    //     }

    //     assembly {
    //         mstore(filteredShipments, filteredCount)
    //     }

    //     return filteredShipments;
    // }
}