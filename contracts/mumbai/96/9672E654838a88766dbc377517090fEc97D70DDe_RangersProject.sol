/**
 *Submitted for verification at polygonscan.com on 2023-07-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title RangersProject - Official Smart Contract for the "Rangers" Project
 * @dev This contract allows the assignment and retrieval of developer points, which represent shares in the "Rangers" project.
 *      The points reflect ownership stakes in 60% of the project, while the remaining 40% always belongs to the contract owner.
 */
contract RangersProject {
    address private owner;
    uint256 private totalPoints;

    struct Developer {
        string name;
        uint256 points;
        bool exists;
    }

    mapping(address => Developer) private developers;
    address[] private developerList;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
        developers[owner] = Developer("Michal Jazdzyk", 1, true);
        developerList.push(owner);
        totalPoints = 1;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function setDeveloperName(address developerAddress, string memory name) external onlyOwner {
        require(bytes(name).length > 0, "Name cannot be empty");
        developers[developerAddress].name = name;
    }

    function assignPoints(address developerAddress, uint256 points) external onlyOwner {
        require(developerAddress != address(0), "Invalid developer address");
        require(points > 0, "Points must be greater than zero");

        if (!developers[developerAddress].exists) {
            developerList.push(developerAddress);
            developers[developerAddress].exists = true;
        }

        developers[developerAddress].points += points;
        totalPoints += points;
    }

    function getTotalPoints() external view returns (uint256) {
        return totalPoints;
    }

    function getDeveloper(address developerAddress) external view returns (string memory, uint256) {
        require(developers[developerAddress].exists, "Developer not found");

        uint256 developerPoints = developers[developerAddress].points;
        if (totalPoints == 0) {
            return ('', 0);
        }

        return (developers[developerAddress].name, developerPoints); 
    }

    function getAllDevelopers() external view returns (string[] memory, address[] memory, uint256[] memory) {
        uint256 totalDevelopers = developerList.length;
        string[] memory nameList = new string[](totalDevelopers);
        uint256[] memory pointsList = new uint256[](totalDevelopers);

        for (uint256 i = 0; i < totalDevelopers; i++) {
            nameList[i] = developers[developerList[i]].name;
            pointsList[i] = developers[developerList[i]].points;
        }

        return (nameList, developerList, pointsList);
    }
}