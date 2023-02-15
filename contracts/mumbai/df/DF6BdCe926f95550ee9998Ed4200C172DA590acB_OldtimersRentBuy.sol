// SPDX-License-Identifier: Mit
// Proof of Concept for Renting & Buying Classic Vehicles
// @autor Oldtimers Offer (A step towards decentralization of the classic vehicle market)

pragma solidity ^0.8.7;

interface ClassicVehicles {
   
   event newVehicle(bool _vehicleCreated);
    
    struct ClassicVehicle{
        uint256 year;
        string make;
        string model;
        string vehicleType;
        uint256 time;
        address owner;
    }

    struct VehicleDetails{
        string exteriorColor;
        string interiorColor;
        string transmission;
        uint256 odometer; //miles
        bool rentAvailable;
        uint256 priceRentPerDay; //The Price is in ETH
        uint ableToAddDetails;
        bool buyAvailable;
        uint256 priceForVehicle; //The Price is in ETH
    }

    struct RentedVehicle{
        uint rentedTimes;
        uint256 lastTimeOfRent;
        address lastTimeRentedBy;
        address[] users;
        address[] usersReviewed;
    }

    struct VehicleOwner{
        address vehicleOwner;
    }

    struct UserReviews{
        uint256[] reviewScore;
    }
}

// SPDX-License-Identifier: Mit
// Proof of Concept for Renting & Buying Classic Vehicles
// @autor Oldtimers Offer (A step towards decentralization of the classic vehicle market)

pragma solidity ^0.8.7;

import {ClassicVehicles}from "./ClassicVehicles.sol";

contract OldtimersRentBuy is ClassicVehicles {

    mapping (uint256 => ClassicVehicle) public vehicles;
    mapping (uint256 => VehicleDetails) public details;
    mapping (uint256 => RentedVehicle) public rented;
    mapping (uint256 => VehicleOwner) public vehicleOwner;
    mapping (uint256 => UserReviews) internal reviews;

    uint256 public vehicleID = 1; //we started with ID 1
    uint public oneDaySeconds = 86400;
    uint256 public rentFee = 0.01 ether; //service fee when user rent a vehicle
    uint256 public buyFee = 0.02 ether; //service fee when user buy a vehicle
    uint256 decimals = 10 ** 18;
    uint256 public accumulatedProfit; //calculated in Wei
    address public Admin;

    constructor() {
        Admin = msg.sender;
    }

    //Add Classic Vehicles for rent
    function addVehicle(uint256 year, string memory make, string memory model, string memory vehicleType) public returns (bool _vehicleCreated) {
        require(keccak256(abi.encodePacked("Car"))==keccak256(abi.encodePacked(vehicleType))  ||
        keccak256(abi.encodePacked("Motorcycle"))==keccak256(abi.encodePacked(vehicleType)) ||
        keccak256(abi.encodePacked("Truck"))==keccak256(abi.encodePacked(vehicleType)),"Incorrect Vehicle Type");
        uint256 time = block.timestamp;
        vehicles[vehicleID] = (ClassicVehicle(year, make, model, vehicleType, time, msg.sender));
        emit newVehicle(_vehicleCreated);
        vehicleOwner[vehicleID] = (VehicleOwner(msg.sender));
        vehicleID++;
    }

    //Only Owner of the Vehicle can add Details and in the period when the vehicle is not rented
    function addDetailsToVehicle(uint256 _vehicleID, string memory exteriorColor, string memory interiorColor, string memory transmission, uint256 odometer, bool rentAvailable, uint256 priceRentPerDay, bool buyAvailable, uint256 priceForVehicle) public {
        require(vehicles[_vehicleID].owner == msg.sender, "Only Owner can add Details to the vehicle");
        require(block.timestamp >= details[_vehicleID].ableToAddDetails,"You can't change Details when the vehicle is rented!");
        details[_vehicleID] = (VehicleDetails(exteriorColor, interiorColor, transmission, odometer, rentAvailable, priceRentPerDay, block.timestamp, buyAvailable, priceForVehicle));
    }

    //Users can rent only available vehicles for rent & owner can't rent their own vehicle
    function rentVehicle(uint256 _vehicleID, uint256 _days) public payable {
        require(details[_vehicleID].rentAvailable == true, "Only available vehicles for rent can be rented");
        require(vehicles[_vehicleID].owner != msg.sender, "Owner can't rent their own vehicle");
        uint256 amountToPay;
        amountToPay = _days * details[_vehicleID].priceRentPerDay * decimals;
        uint256 amount;
        amount = amountToPay + rentFee;
        require(msg.value >= amount, "You want to pay less than the owner asked for the vehicle");
        accumulatedProfit += msg.value - amountToPay;
        uint256 time=block.timestamp;
        rented[_vehicleID].rentedTimes += 1;
        rented[_vehicleID].lastTimeOfRent = time;
        rented[_vehicleID].lastTimeRentedBy = msg.sender;
        rented[_vehicleID].users.push(msg.sender);
        details[_vehicleID].rentAvailable = false;
        details[_vehicleID].ableToAddDetails = block.timestamp + (_days * oneDaySeconds);
        sentMoneyToVehicleOwner(vehicles[_vehicleID].owner, amountToPay);
    }

    //Sent money from smart contrant to Owner of Vehicle, when somebody rent a vehicle
    function sentMoneyToVehicleOwner(address _to, uint _value) internal {
        payable(_to).transfer(_value);
    }

    //Only user who rent a vehicle can give a review score
    function giveReviewScore(uint256 _vehicleID, uint256 score) public {
        require(existsUser(_vehicleID, msg.sender) == true, "Only users who rent a vehicle can give a score");
        require(score <= 10, "Users can give a score between 0 and 10");
        require(userVoted(_vehicleID, msg.sender) == false, "Users can give a score only one time per vehicle");
        reviews[_vehicleID].reviewScore.push(score);
        rented[_vehicleID].usersReviewed.push(msg.sender);
    }

    //You can see users review score for some vehicle
    function getReviews(uint256 _vehicleID) external view returns (UserReviews memory) {
        return reviews[_vehicleID];
    }

    //Function which help us to find if the user exist in list of rented vihicles
    function existsUser(uint _vehicleID, address user) internal view returns (bool) {
    for (uint i = 0; i < rented[_vehicleID].users.length; i++) {
        if (rented[_vehicleID].users[i] == user) {
            return true;
        }
      }
      return false;
    }

     //This function help us to secure that users can vote only one time per vehicle
    function userVoted(uint _vehicleID, address user) internal view returns (bool) {
    for (uint i = 0; i < rented[_vehicleID].usersReviewed.length; i++) {
        if (rented[_vehicleID].usersReviewed[i] == user) {
            return true;
        }
      }
      return false;
    }

    //Creator of smart contract can change service fee
    function changeRentFee(uint newPrice) public {
       require(Admin == msg.sender, "Only creator of the smart contract can chagen service fee");
       uint Price;
       Price = newPrice * 10**16;
       rentFee = Price;
    }

    //Creator of smart contract can change buy fee
    function changeBuyFee(uint newPrice) public {
       require(Admin == msg.sender, "Only creator of the smart contract can change service fee");
       uint Price;
       Price = newPrice * 10**16;
       buyFee = Price;
    }

    //Users can buy only available vehicles for buying & owner can't buy their own vehicle
    function buyVehicle(uint256 _vehicleID) public payable {
        require(details[_vehicleID].buyAvailable == true, "Only available vehicles for buying can be buy");
        require(vehicles[_vehicleID].owner != msg.sender, "Owner can't buy their own vehicle");
        require(block.timestamp >= details[_vehicleID].ableToAddDetails,"You can't buy a vehicle when is the vehicle currently rented!");
        uint256 amountToPay;
        amountToPay = details[_vehicleID].priceForVehicle * decimals;
        uint256 amount;
        amount = amountToPay + buyFee;
        require(msg.value >= amount, "You want to pay less than the owner asked for the vehicle");
        accumulatedProfit += msg.value - amountToPay;
        sentMoneyToVehicleOwner(vehicles[_vehicleID].owner, amountToPay);
        details[_vehicleID].rentAvailable = false;
        details[_vehicleID].buyAvailable = false;
        vehicles[_vehicleID].owner = msg.sender;
        vehicleOwner[_vehicleID].vehicleOwner = msg.sender;
    }

}