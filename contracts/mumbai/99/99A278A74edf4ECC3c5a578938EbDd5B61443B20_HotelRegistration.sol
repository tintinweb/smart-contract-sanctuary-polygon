// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ICustomerRegistration.sol";

contract HotelRegistration {
    address public admin;
    ICustomerRegistration public customerContract;

    enum HotelRegistrationStatus {
        Pending,
        Approved,
        Rejected
    }

    struct Hotel {
        string name;
        string description;
        address owner;
        string location;
        uint256 rating;
        uint256 numRatings;
        HotelRegistrationStatus status;
    }

    mapping(address => Hotel) hotels;
    mapping(address => bool) hotelRegistrationRequests;
    mapping(address => mapping(address => uint256)) hotelRatings;

    // modifiers
    modifier onlyOwner() {
        require(
            msg.sender == admin,
            "Only contract owner can perform this action"
        );
        _;
    }

    modifier onlyRegisteredCustomer(address _customerAddress) {
        (, , , , bool isRegistered) = customerContract.getCustomer(
            _customerAddress
        );
        require(isRegistered, "Customer is not registered");
        _;
    }

    // constructor
    constructor() {
        admin = msg.sender;
    }

    function updateContractAddresses(
        address _customerContractAddr
    ) external onlyOwner {
        customerContract = ICustomerRegistration(_customerContractAddr);
    }

    function setOwner(address _newOwner) public onlyOwner {
        admin = _newOwner;
    }

    function requestHotelRegistration(
        string memory _name,
        string memory _description,
        string memory _location
    ) public {
        require(
            !hotelRegistrationRequests[msg.sender],
            "Registration request already submitted for this address"
        );

        hotels[msg.sender] = Hotel({
            name: _name,
            description: _description,
            owner: msg.sender,
            location: _location,
            rating: 0,
            numRatings: 0,
            status: HotelRegistrationStatus.Pending
        });

        hotelRegistrationRequests[msg.sender] = true;
    }

    function processHotelRegistration(
        address _hotelOwner,
        bool _isApproved
    ) external onlyOwner {
        require(
            hotelRegistrationRequests[_hotelOwner],
            "No registration request exists for this address"
        );

        if (_isApproved) {
            hotels[_hotelOwner].status = HotelRegistrationStatus.Approved;
        } else {
            hotels[_hotelOwner].status = HotelRegistrationStatus.Rejected;
        }
        hotelRegistrationRequests[_hotelOwner] = false;
    }

    function rateHotel(
        address _hotelOwner,
        uint256 _rating
    ) external onlyRegisteredCustomer(msg.sender) {
        require(
            hotels[_hotelOwner].status == HotelRegistrationStatus.Approved,
            "Hotel registration not approved yet"
        );
        require(
            _rating >= 1 && _rating <= 5,
            "Rating should be between 1 and 5"
        );

        uint256 currentRating = hotelRatings[_hotelOwner][msg.sender];
        if (currentRating > 0) {
            // update existing rating
            hotels[_hotelOwner].rating =
                hotels[_hotelOwner].rating -
                currentRating +
                _rating;
        } else {
            // add new rating
            hotels[_hotelOwner].rating += _rating;
            hotels[_hotelOwner].numRatings += 1;
        }
        hotelRatings[_hotelOwner][msg.sender] = _rating;
    }

    function getHotelAverageRating(
        address _hotelOwner
    ) public view returns (uint256) {
        require(
            hotels[_hotelOwner].status == HotelRegistrationStatus.Approved,
            "Hotel registration not approved yet"
        );
        require(hotels[_hotelOwner].numRatings > 0, "No ratings available");

        uint256 sum = hotels[_hotelOwner].rating;
        uint256 numRatings = hotels[_hotelOwner].numRatings;
        uint256 scalingFactor = 10 ** (18 - numRatings); // scaling factor decreases as numRatings increase

        uint256 scaledRating = (sum * scalingFactor) / numRatings;
        uint256 average = (scaledRating * 5) / 10 ** 18; // scale back to 0-5 range

        return average;
    }

    // getter functions
    function getHotelOwnerData(
        address _hotelOwnerAddress
    )
        public
        view
        returns (
            string memory,
            string memory,
            address,
            string memory,
            uint256,
            uint256,
            HotelRegistrationStatus
        )
    {
        Hotel memory hotel = hotels[_hotelOwnerAddress];
        return (
            hotel.name,
            hotel.description,
            hotel.owner,
            hotel.location,
            hotel.rating,
            hotel.numRatings,
            hotel.status
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICustomerRegistration {
    function getCustomer(
        address _customerAddress
    )
        external
        view
        returns (
            string memory name,
            string memory email,
            string memory phoneNumber,
            uint256 registrationDate,
            bool isRegistered
        );
}