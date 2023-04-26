/**
 *Submitted for verification at polygonscan.com on 2023-04-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Data {
    struct Object {
        uint256 weight;
        uint256 bloodPressure;
        uint256 pulse;
        string name;
    }

    // mapping from index to the data object
    mapping(uint256 => Object) public objects;

    uint256 public listLength;

    constructor() {
        listLength = 0;
    }

    // Function to add a new data entry to the linked list. Currently public -> CHANGE TO ONLY OWNER
    function addObject(
        string memory _name,
        uint256 _weight,
        uint256 _bloodPressure,
        uint256 _pulse
    ) public {
        uint256 currentIndex = listLength;

        Object memory newEntry = Object({
            weight: _weight,
            name: _name,
            bloodPressure: _bloodPressure,
            pulse: _pulse
        });
        objects[currentIndex] = newEntry;

        listLength++;
    }

    function getObject(
        uint256 index
    ) public view returns (string memory, uint256, uint256, uint256) {
        require(index < listLength, "Index out of range");

        string memory returnName = objects[index].name;
        uint256 returnWeight = objects[index].weight;
        uint256 returnPulse = objects[index].pulse;
        uint256 returnBloodPressure = objects[index].bloodPressure;

        return (returnName, returnWeight, returnBloodPressure, returnPulse);
    }

    function getListLength() public view returns (uint256) {
        return listLength;
    }
}