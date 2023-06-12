// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract PassportAccess {
    enum AccessLevel {
        None,
        Workshop,
        Manufacturer,
        Owner
    }

    mapping(address => AccessLevel) public accessLevels;

    event WorkshopAdded(address workshop);
    event MemberRemoved(address member);
    event ManufacturerAdded(address manufacturer);

    address public owner;

    constructor() {
        owner = msg.sender;
        accessLevels[msg.sender] = AccessLevel.Owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    function delPassportAccess(address _member) public onlyOwner {
        accessLevels[_member] = AccessLevel.None;
        emit MemberRemoved(_member);
    }

    function addWorkshop(address _workshop) public onlyOwner {
        accessLevels[_workshop] = AccessLevel.Workshop;
        emit WorkshopAdded(_workshop);
    }
    
    function addManufacturer(address _manufacturer) public onlyOwner {
        accessLevels[_manufacturer] = AccessLevel.Manufacturer;
        emit ManufacturerAdded(_manufacturer);
    }

}