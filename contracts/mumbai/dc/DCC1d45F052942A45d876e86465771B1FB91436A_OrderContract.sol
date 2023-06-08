// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OrderContract {
    struct Order {
        uint256 id;
        string purity;
        uint256 volume;
        uint256 density;
        uint256 pressure;
        uint256 temperature;
        uint256 price;
        string longitude;
        string latitude;
        uint256 co2footprint;
    }

    Order[] public orders;
    uint256 private orderCount = 0;

    event OrderCreated(
        uint256 id,
        address indexed sender,
        string indexed purity,
        uint256 indexed density
    );

    function createOrder(
        string memory _purity,
        uint256 _volume,
        uint256 _density,
        uint256 _pressure,
        uint256 _temperature,
        uint256 _price,
        string memory _longitude,
        string memory _latitude,
        uint256 _co2footprint
    ) public {
        require(msg.sender != address(0), "Invalid sender address!");
        Order memory newOrder = Order(
            orderCount,
            _purity,
            _volume,
            _density,
            _pressure,
            _temperature,
            _price,
            _longitude,
            _latitude,
            _co2footprint
        );

        orders.push(newOrder);
        orderCount++;

        emit OrderCreated(newOrder.id, msg.sender, _purity, _density);
    }

    function getOrderCount() public view returns (uint256) {
       return orderCount;     
    }

    function getOrder(uint256 index) public view returns (Order memory) {
        require(index < orders.length, "Index out of range");
        return orders[index];
    }
}