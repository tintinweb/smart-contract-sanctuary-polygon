/**
 *Submitted for verification at polygonscan.com on 2023-05-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract EvvelandEventUsers {
    address payable public owner;
    mapping(uint256 => address[]) private eventUsers;
    mapping(uint256 => mapping(address => bool)) private userExists;
    mapping(uint256 => mapping(uint256 => mapping(address => bool)))
        private visitedStand;
    mapping(address => mapping(uint256 => uint256)) private totalUserVisits;

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not authorized!");
        _;
    }

    function getEventUsers(uint256 _venueId)
        public
        view
        returns (address[] memory)
    {
        return eventUsers[_venueId];
    }

    function checkUserExists(uint256 _venueId, address _user)
        public
        view
        returns (bool)
    {
        return userExists[_venueId][_user];
    }

    function hasVisitedStand(
        address _user,
        uint256 _venueId,
        uint256 _standId
    ) public view returns (bool) {
        return visitedStand[_venueId][_standId][_user];
    }

    function visitStand(uint256 _venueId, uint256 _standId) public {
        address _user = msg.sender;
        bool visited = hasVisitedStand(_user, _venueId, _standId);
        require(!visited, "Already visited this stand");
        visitedStand[_venueId][_standId][_user] = true;
        totalUserVisits[_user][_venueId]++;

        bool userAlreadyExists = checkUserExists(_venueId, _user);
        if (!userAlreadyExists) {
            userExists[_venueId][_user] = true;
            eventUsers[_venueId].push(_user);
        }
    }

    function getUserVisitsList(uint256 _venueId)
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        mapping(address => bool) storage _userExists = userExists[_venueId];
        uint256 userCount = 0;
        // Count the number of users for the given venue ID
        for (uint256 i = 0; i < eventUsers[_venueId].length; i++) {
            address user = eventUsers[_venueId][i];
            if (_userExists[user]) {
                userCount++;
            }
        }

        // Initialize arrays to store the users and visit counts
        address[] memory users = new address[](userCount);
        uint256[] memory visits = new uint256[](userCount);

        // Populate the arrays with users and visit counts
        uint256 index = 0;
        for (uint256 i = 0; i < eventUsers[_venueId].length; i++) {
            address user = eventUsers[_venueId][i];
            if (_userExists[user]) {
                users[index] = user;
                visits[index] = totalUserVisits[user][_venueId];
                index++;
            }
        }

        return (users, visits);
    }

    function withdraw() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No balance to withdraw");
        owner.transfer(contractBalance);
    }
}