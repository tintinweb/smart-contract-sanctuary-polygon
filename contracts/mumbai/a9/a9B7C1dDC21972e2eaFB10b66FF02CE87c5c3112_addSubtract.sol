// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract addSubtract {
    address public admin;
    mapping(address => bool) public users;
    uint public number;

     modifier onlyAdmin() {
        require(msg.sender == admin, "Only the admin can call this function");
        _;
    }

    modifier onlyAdminOrUser() {
        require(msg.sender == admin || users[msg.sender], "Only admin or users can call this function");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function assignUserRole(address user) public {
        require(msg.sender == admin, "Only admin can assign user roles");
        users[user] = true;
    }

    function removeUserRole(address user) public {
        require(msg.sender == admin, "Only admin can remove user roles");
        users[user] = false;
    }

    function isUser(address user) public view returns (bool) {
        return users[user];
    }

    function subtract() public onlyAdmin {
        number -= 1;
    }

    function add() public onlyAdminOrUser {
        number += 1;
    }
}