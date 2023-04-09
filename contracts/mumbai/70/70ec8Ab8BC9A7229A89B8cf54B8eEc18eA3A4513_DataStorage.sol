// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DataStorage {
    // Memory
    bool private isInitialized;
    bool public paused;
    mapping(address => bool) private owners;
    mapping(address => bool) private allowedAddresses;
    mapping(string => mapping(string => mapping(string => bytes))) private data;

    // Modifiers
    modifier onlyOwner() {
        require(owners[msg.sender] == true, "Only owners allowed");
        _;
    }

    modifier onlyAllowed() {
        require(allowedAddresses[msg.sender] == true, "Address not allowed");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Cotract is paused");
        _;
    }

    // Events
    event DataStored(string workspaceId, string bucketId, string uid, bytes payload);

    function initialize(address _owner) external {
        require(!isInitialized, "Already initialized");
        isInitialized = true;
        owners[_owner] = true;
        allowedAddresses[_owner] = true;
        paused = false;
    }

    // Check if an address is an owner
    function isOwner(address _address) external view returns (bool) {
        return owners[_address];
    }

    // Pause contract
    function pause() external onlyOwner {
        paused = true;
    }

    // Unpause contract
    function unpause() external onlyOwner {
        paused = false;
    }

    // Add a new allowed address
    function addAllowedAddress(address _address) external onlyOwner {
        allowedAddresses[_address] = true;
    }

    // Remove an allowed address
    function removeAllowedAddress(address _address) external onlyOwner {
        allowedAddresses[_address] = false;
    }

    // Check if an address is allowed to call setData
    function isAllowed(address _address) external view returns (bool) {
        return allowedAddresses[_address];
    }

    // Set data with workspaceId, bucketId and uid
    function setData(
        string memory workspaceId,
        string memory bucketId,
        string memory uid,
        bytes memory payload
    ) external whenNotPaused onlyAllowed {
        data[workspaceId][bucketId][uid] = payload;
        emit DataStored(workspaceId, bucketId, uid, payload);
    }

    // Get data by workspaceId, bucketId and uid
    function getData(
        string memory workspaceId,
        string memory bucketId,
        string memory uid
    ) external view whenNotPaused onlyAllowed returns (bytes memory) {
        return data[workspaceId][bucketId][uid];
    }
}