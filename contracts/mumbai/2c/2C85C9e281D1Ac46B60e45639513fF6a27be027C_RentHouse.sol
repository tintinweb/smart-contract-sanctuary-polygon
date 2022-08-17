// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

error RentHouse__PropertyNotActive();
error RentHouse__NotEnoughETHSent();
error RentHouse__PropertyNotAvailableForTheSelectedDate();
error RentHouse__NotOwner();

contract RentHouse {
    struct Property {
        uint256 property_id;
        address owner;
        string property_name;
        string property_description;
        uint256 price;
        bool isActive;
        bool[] isBooked;
    }

    struct Booking {
        uint256 property_id;
        address usesr;
        uint256 checkinDate;
        uint256 checkoutDate;
    }

    event PropertyBooked(uint256 property_id);
    event PropertyRented(uint256 booking_id);

    uint256 public propertyID = 0;
    uint256 public bookingID = 0;

    mapping(uint256 => Property) public properties;
    mapping(uint256 => Booking) public bookings;

    modifier isPropertyActive(
        uint256 property_id,
        uint256 checkinDate,
        uint256 checkoutDate
    ) {
        Property storage property = properties[property_id];
        if (!property.isActive) {
            revert RentHouse__PropertyNotActive();
        }

        for (uint256 i = checkinDate; i < checkoutDate; i++) {
            if (property.isBooked[i] == true) {
                revert RentHouse__PropertyNotAvailableForTheSelectedDate();
            }
        }
        _;
    }

    function rentOutProperty(
        string memory property_name,
        string memory property_description,
        uint256 price
    ) public {
        propertyID = propertyID + 1;
        properties[propertyID] = Property(
            propertyID,
            msg.sender,
            property_name,
            property_description,
            price,
            true,
            new bool[](365)
        );
        emit PropertyBooked(propertyID);
    }

    function rentProperty(
        uint256 property_id,
        uint256 checkinDate,
        uint256 checkoutDate
    ) public payable isPropertyActive(property_id, checkinDate, checkoutDate) {
        if (msg.value < (properties[property_id].price * (checkoutDate - checkinDate))) {
            revert RentHouse__NotEnoughETHSent();
        }
        bookingID = bookingID + 1;
        bookings[bookingID] = Booking(property_id, msg.sender, checkinDate, checkoutDate);
        for (uint256 i = checkinDate; i < checkoutDate; i++) {
            properties[property_id].isBooked[i] = true;
        }
        emit PropertyRented(bookingID);
    }

    function getPropertyName(uint256 property_id) public view returns (string memory) {
        return properties[property_id].property_name;
    }

    function getPropertyId() public view returns (uint256) {
        return propertyID;
    }

    function getBookingId() public view returns (uint256) {
        return bookingID;
    }

    function makePropertyAsInActive(uint256 propert_id) public {
        if (properties[propert_id].owner != msg.sender) {
            revert RentHouse__NotOwner();
        }
        properties[propert_id].isActive = false;
    }
}