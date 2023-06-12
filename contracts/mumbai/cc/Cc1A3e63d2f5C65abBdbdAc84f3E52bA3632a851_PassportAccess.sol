// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract PassportAccess {
    enum AccessLevel {
        None,
        Workshop,
        Owner
    }

    mapping(address => AccessLevel) public accessLevels;

    event WorkshopAdded(address workshop);
    event WorkshopRemoved(address );

    address public owner;

    constructor() {
        owner = msg.sender;
        accessLevels[msg.sender] = AccessLevel.Owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyWorkshop() {
        require(accessLevels[msg.sender] >= AccessLevel.Workshop, "Only Workshop");
        _;
    }

    function delWorkshop(address _workshop) public onlyOwner {
        accessLevels[_workshop] = AccessLevel.None;
        emit WorkshopRemoved(_workshop);
    }

    function addMember(address _workshop) public onlyOwner {
        accessLevels[_workshop] = AccessLevel.Workshop;
        emit WorkshopAdded(_workshop);
    }

}