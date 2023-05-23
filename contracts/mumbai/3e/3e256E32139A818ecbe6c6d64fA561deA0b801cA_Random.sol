// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Random {
    mapping(address => bool) public admins;

    constructor() {
        admins[msg.sender] = true;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Caller is not an admin");
        _;
    }

    function addAdmin(address newAdmin) public onlyAdmin {
        admins[newAdmin] = true;
    }

    function removeAdmin(address adminToRemove) public onlyAdmin {
        require(msg.sender != adminToRemove, "Cannot remove oneself as admin");
        admins[adminToRemove] = false;
    }

    function growthAvailableFunds() public view onlyAdmin returns (uint256) {
        return 1 * 1e18;
    }
}