// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Counter {
    uint public count;
    mapping(address => uint) public countsByUser;
    uint public numUsers;
    address[] public userAccounts;
    address public owner;
    address public baller;
    uint public lastPayment;

    constructor() {
        owner = msg.sender;
    } 

    function increment(uint incrementBy) public {
        count += incrementBy;
        _updateUserCount(msg.sender, incrementBy);
    }

    function incrementBy1() public {
        count++;
        _updateUserCount(msg.sender, 1);
    }

    // should not show up on sidebar
    function _updateUserCount(address user, uint incrementBy) private {
        if (countsByUser[user] == 0) {
            numUsers++;
            userAccounts.push(user);
        }
        countsByUser[user] += incrementBy;
    }

    function becomeTheBaller() payable public {
        require(msg.value > lastPayment, "not enough bread");
        baller = msg.sender;
        lastPayment = msg.value;
    }

    function addTwoNumbers(int a, int b) public pure returns (int) {
        return a + b;
    }

    // should not show up on sidebar
    function internalMultiply(int a, int b) internal pure returns (int) {
        return a * b;
    }

    function getAllCounts() public view returns (address[] memory, uint256[] memory) {
        address[] memory keys = new address[](numUsers);
        uint256[] memory values = new uint256[](numUsers);

        for (uint i=0; i < numUsers; i++) {
            address account = userAccounts[i];
            keys[i] = account;
            values[i] = countsByUser[account];
        }

        return (keys, values);
    }

}