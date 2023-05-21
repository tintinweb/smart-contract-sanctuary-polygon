// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./SLA.sol";

contract Manager {
    mapping(address => address[]) providerSLAs;
    mapping(address => address[]) consumerSLAs;
    address[] public allSLAs;

    // events
    event SLAContractCreated(address indexed newContract);

    constructor() {}

    function getMyProviders() public view returns (address[] memory) {
        return providerSLAs[msg.sender];
    }

    function getMyConsumers() public view returns (address[] memory) {
        return consumerSLAs[msg.sender];
    }

    // deploy a new SLA contract
    function createSLAContract() public {
        address slaAddress = address(new SLA());
        allSLAs.push(slaAddress);
        providerSLAs[msg.sender].push(slaAddress);
        emit SLAContractCreated(slaAddress);
    }
}