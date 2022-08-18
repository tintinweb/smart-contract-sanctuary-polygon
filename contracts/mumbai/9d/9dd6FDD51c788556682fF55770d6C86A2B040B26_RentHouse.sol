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
        address user;
        uint256 checkinDate;
        uint256 checkoutDate;
    }

    event PropertyBooked(uint256 indexed property_id);
    event PropertyRented(uint256 indexed booking_id);

    uint256 public propertyID = 0;
    uint256 public bookingID = 0;

    // Property Array
    Property[] props;

    mapping(uint256 => Property) public properties;
    mapping(uint256 => Booking) public bookings;

    ////////////////////
    //    Modifiers   //
    ////////////////////

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

    ////////////////////
    // Main Functions //
    ////////////////////

    /*
     * @notice Method for listing your property for rent.
     * @params property_name: Name of the property
     * @params property_description: Description of the property
     * @params price: Price per day for renting the property
     */

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
        props.push(properties[propertyID]);
        emit PropertyBooked(propertyID);
    }

    /*
     * @notice Method for renting the listed property
     * @params property_id: Property ID
     * @params checkinDate: Check-in Date of the rented property
     * @params checkoutDate: Check-out Date of the rented property
     */

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

    /*
     * @notice Method for making the property inactive
     * @params propert_id: Property ID
     * @dev Only owner of that property can deactivate their property
     */
    function makePropertyAsInActive(uint256 propert_id) public {
        if (properties[propert_id].owner != msg.sender) {
            revert RentHouse__NotOwner();
        }
        properties[propert_id].isActive = false;
    }

    //////////////////////
    // Getter Functions //
    //////////////////////

    function getPropertyName(uint256 property_id) public view returns (string memory) {
        return properties[property_id].property_name;
    }

    function getPropertyDescription(uint256 property_id) public view returns (string memory) {
        return properties[property_id].property_description;
    }

    function getPropertyOwner(uint256 property_id) public view returns (address) {
        return properties[property_id].owner;
    }

    function getPropertyPrice(uint256 property_id) public view returns (uint256) {
        return properties[property_id].price;
    }

    function getPropertyUser(uint256 booking_id) public view returns (address) {
        return bookings[booking_id].user;
    }

    function getBookingCheckinDate(uint256 booking_id) public view returns (uint256) {
        return bookings[booking_id].checkinDate;
    }

    function getBookingCheckoutDate(uint256 booking_id) public view returns (uint256) {
        return bookings[booking_id].checkoutDate;
    }

    function getPropertyId() public view returns (uint256) {
        return propertyID;
    }

    function getBookingId() public view returns (uint256) {
        return bookingID;
    }

    function getPropertyArray() public view returns (Property[] memory) {
        return props;
    }
}