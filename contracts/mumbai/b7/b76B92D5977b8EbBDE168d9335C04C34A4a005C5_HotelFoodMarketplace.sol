// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/ICustomerRegistration.sol";
import "./interfaces/IHotelRegistration.sol";

contract HotelFoodMarketplace {
    address public admin;
    ICustomerRegistration public customerContract;
    IHotelRegistration public hotelContract;

    struct Food {
        address hotelOwner;
        FoodDetails[] foodDetails;
        bool isFresh;
        uint maxFreshDuration; // maximum fresh duration of all food items in seconds
        uint freshnessTimestamp; // timestamp when the food items were considered fresh
    }

    // Struct to store food details
    struct FoodDetails {
        string name;
        uint price;
        uint freshDuration;
        uint startTimeStamp;
        uint endTimeStamp;
    }

    // modifiers
    modifier onlyOwner() {
        require(
            msg.sender == admin,
            "Only contract owner can perform this action"
        );
        _;
    }

    // constructor
    constructor() {
        admin = msg.sender;
    }

    // Mapping to store food items for a hotel owner
    mapping(bytes32 => Food) public idToFood;

    // Mapping to store hotelOwner to foodids
    mapping(address => bytes32[]) public hotelOwnerToFoodIds;

    // modifiers

    modifier onlyRegisteredCustomer(address _customerAddress) {
        (, , , , bool isRegistered) = customerContract.getCustomer(
            _customerAddress
        );
        require(isRegistered, "Customer is not registered");
        _;
    }

    modifier onlyRegisteredHotelOwner(address _hotelOwner) {
        (
            ,
            ,
            ,
            ,
            ,
            ,
            IHotelRegistration.HotelRegistrationStatus status
        ) = hotelContract.getHotelOwnerData(_hotelOwner);
        require(
            status == IHotelRegistration.HotelRegistrationStatus.Approved,
            "Customer is not registered"
        );
        _;
    }

    //functions

    function updateContractAddresses(
        address _customerContractAddr,
        address _hotelContractAddr
    ) external onlyOwner {
        customerContract = ICustomerRegistration(_customerContractAddr);
        hotelContract = IHotelRegistration(_hotelContractAddr);
    }

    function addFood(
        FoodDetails[] memory _newFoodDetails
    ) external onlyRegisteredHotelOwner(msg.sender) {
        bytes32 foodId = keccak256(
            abi.encodePacked(msg.sender, block.timestamp)
        );
        Food storage food = idToFood[foodId];
        if (food.hotelOwner == address(0)) {
            food.hotelOwner = msg.sender;
            food.isFresh = true;
            food.freshnessTimestamp = block.timestamp;
        }

        for (uint i = 0; i < _newFoodDetails.length; i++) {
            FoodDetails memory newFood = _newFoodDetails[i];
            newFood.startTimeStamp = block.timestamp;
            newFood.endTimeStamp =
                block.timestamp +
                (newFood.freshDuration * 1 hours);
            food.foodDetails.push(newFood);

            if (newFood.freshDuration > food.maxFreshDuration) {
                food.maxFreshDuration = newFood.freshDuration;
            }
        }

        updateFoodFreshness(foodId);
    }

    function removeFood(
        bytes32 foodId,
        uint foodIndex
    ) public onlyRegisteredHotelOwner(msg.sender) {
        Food storage food = idToFood[foodId];
        require(food.foodDetails.length > foodIndex, "Invalid food index");

        uint freshDuration = food.foodDetails[foodIndex].freshDuration;
        food.foodDetails[foodIndex] = food.foodDetails[
            food.foodDetails.length - 1
        ];
        food.foodDetails.pop();

        if (freshDuration == food.maxFreshDuration) {
            food.maxFreshDuration = 0;
            for (uint i = 0; i < food.foodDetails.length; i++) {
                if (food.foodDetails[i].freshDuration > food.maxFreshDuration) {
                    food.maxFreshDuration = food.foodDetails[i].freshDuration;
                }
            }
        }

        updateFoodFreshness(foodId);
    }

    function updateFoodFreshness(bytes32 foodId) internal {
        Food storage food = idToFood[foodId];
        uint currentTimestamp = block.timestamp;
        if (
            currentTimestamp > food.freshnessTimestamp + food.maxFreshDuration
        ) {
            food.isFresh = false;
        }
    }

    function buyFood(
        bytes32 foodId,
        uint foodIndex
    ) public payable onlyRegisteredCustomer(msg.sender) {
        Food storage food = idToFood[foodId];
        require(food.foodDetails.length > foodIndex, "Invalid food index");
        require(food.isFresh, "Food is not fresh");

        FoodDetails storage foodDetails = food.foodDetails[foodIndex];
        require(msg.value >= foodDetails.price, "Insufficient funds");

        // Transfer funds to hotel owner
        payable(food.hotelOwner).transfer(msg.value);

        // Remove food item from marketplace
        removeFood(foodId, foodIndex);

        // Add food item to hotel owner's list of sold food items
        hotelOwnerToFoodIds[food.hotelOwner].push(foodId);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IHotelRegistration {
    enum HotelRegistrationStatus {
        Pending,
        Approved,
        Rejected
    }

    function getHotelOwnerData(
        address _hotelOwnerAddress
    )
        external
        view
        returns (
            string memory,
            string memory,
            address,
            string memory,
            uint256,
            uint256,
            HotelRegistrationStatus
        );
}