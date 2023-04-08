// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract humanitarianAid {
    address public owner;

    struct AidPackage {
        uint id;
        address recipient;
        uint amount;
        bool distributed;
    }

    mapping(uint => AidPackage) public aidPackages;
    uint public packageCount;

    event PackageCreated(uint indexed id, address indexed recipient, uint amount);
    event PackageDistributed(uint indexed id);

    constructor() {
        owner = msg.sender;
    }

    function createPackage(address recipient, uint amount) external onlyOwner {
        packageCount++;
        aidPackages[packageCount] = AidPackage(packageCount, recipient, amount, false);
        emit PackageCreated(packageCount, recipient, amount);
    }

    function distributePackage(uint id) external onlyOwner {
        require(id <= packageCount, "Invalid package ID");
        require(!aidPackages[id].distributed, "Package already distributed");

        aidPackages[id].distributed = true;
        emit PackageDistributed(id);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
}