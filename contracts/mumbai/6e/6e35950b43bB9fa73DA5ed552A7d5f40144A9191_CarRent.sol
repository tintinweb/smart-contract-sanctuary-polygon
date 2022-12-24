//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

contract CarRent {
    struct Driver {
        address addr;
        bool isAvailable;
    }

    uint driverId = 0;
    mapping(uint => Driver) public drivers;

    function createDriver() public /*string memory picture*/ {
        drivers[driverId++] = Driver(msg.sender, true);
        // Driver storage driver = drivers[driverIdx++];
        // driver.driverAdd = msg.sender;
        // driver.picture = picture;
    }

    struct Rider {
        address addr;
    }

    struct Ride {
        address driver;
        uint did;
        uint id;
        address rider;
        uint startTime;
        uint endTime;
        uint price;
    }

    mapping(uint => Rider) public riders;
    uint rid = 0;

    Ride[] public rides;

    // uint price = 1;
    // Function to request a ride
    function requestRide(uint id, uint price) public {
        // Check that the driver is available
        require(drivers[id].isAvailable, "Driver is not available");
        // require(msg.value >= price, "Pay in Full");
        // Create a new ride record
        rides.push(
            Ride({
                driver: drivers[id].addr,
                rider: msg.sender,
                did: id,
                id: rid,
                startTime: block.timestamp,
                endTime: 0,
                price: price
            })
        );

        riders[rid++] = Rider(msg.sender);

        drivers[id].isAvailable = false;
    }

    function completeRide(uint rideId) public payable {
        Ride storage ride = rides[rideId];

        // Check that the caller is the driver
        require(
            ride.driver == msg.sender,
            "Only the driver can complete the ride"
        );
        drivers[ride.did].isAvailable = true;
        // Update the end time and transfer the payment to the driver
        ride.endTime = block.timestamp;
        // ride.driver.transfer(ride.price);
    }

    function showRides() public view returns (Ride[] memory) {
        uint count = 0;
        for (uint i = 0; i < rid; i++) {
            if (rides[i].rider == msg.sender || rides[i].driver == msg.sender)
                count++;
        }

        Ride[] memory items = new Ride[](count);

        uint curIdx = 0;
        for (uint i = 0; i < rid; i++) {
            if (rides[i].rider == msg.sender || rides[i].driver == msg.sender) {
                items[curIdx++] = rides[i];
            }
        }

        return items;
    }

    function showDriver() public view returns (Driver[] memory) {
        Driver[] memory items = new Driver[](driverId);

        // uint curIdx = 0;
        for (uint i = 0; i < driverId; i++) {
            items[i] = drivers[i];
        }

        return items;
    }
}