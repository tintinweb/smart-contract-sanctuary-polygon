// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Log {

    address public manager;

    bytes32 public subjectType;
    bytes32 public subjectReference;
    bytes32 public subjectLabel;

    address currentOwner;
    address[] owners;

    modifier isManager() {
        require(msg.sender == manager, "Caller is not Manager");
        _;
    }

    constructor() {
        manager = msg.sender;
    }

    function setSubject(bytes32 _subjectType, bytes32 _subjectReference, bytes32 _subjectLabel, address _firstOwner) external isManager {
        subjectType = _subjectType;
        subjectReference = _subjectReference;
        subjectLabel = _subjectLabel;
        currentOwner = _firstOwner;
        owners.push(_firstOwner);
    }

    function getCurrentOwner() external view returns (address) {
        return currentOwner;
    }

    function getOwners() external view returns (address[] memory) {
        return owners;
    }
}