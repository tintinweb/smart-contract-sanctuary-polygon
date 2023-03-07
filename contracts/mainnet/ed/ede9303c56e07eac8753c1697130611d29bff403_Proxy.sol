/**
 *Submitted for verification at polygonscan.com on 2023-03-07
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

/// @title Fractal registry v0
/// @author Antoni Dikov and Shelby Doolittle
contract FractalRegistry {
    address root;
    mapping(address => bool) public delegates;

    mapping(address => bytes32) fractalIdForAddress;
    mapping(string => mapping(bytes32 => bool)) userLists;

    constructor(address _root) {
        root = _root;
    }

    /// @param addr is Eth address
    /// @return FractalId as bytes32
    function getFractalId(address addr) external view returns (bytes32) {
        return fractalIdForAddress[addr];
    }

    /// @notice Adds a user to the mapping of Eth address to FractalId.
    /// @param addr is Eth address.
    /// @param fractalId is FractalId in bytes32.
    function addUserAddress(address addr, bytes32 fractalId) external {
        requireMutatePermission();
        fractalIdForAddress[addr] = fractalId;
    }

    /// @notice Removes an address from the mapping of Eth address to FractalId.
    /// @param addr is Eth address.
    function removeUserAddress(address addr) external {
        requireMutatePermission();
        delete fractalIdForAddress[addr];
    }

    /// @notice Checks if a user by FractalId exists in a specific list.
    /// @param userId is FractalId in bytes32.
    /// @param listId is the list id.
    /// @return bool if the user is the specified list.
    function isUserInList(bytes32 userId, string memory listId)
        external
        view
        returns (bool)
    {
        return userLists[listId][userId];
    }

    /// @notice Add user by FractalId to a specific list.
    /// @param userId is FractalId in bytes32.
    /// @param listId is the list id.
    function addUserToList(bytes32 userId, string memory listId) external {
        requireMutatePermission();
        userLists[listId][userId] = true;
    }

    /// @notice Remove user by FractalId from a specific list.
    /// @param userId is FractalId in bytes32.
    /// @param listId is the list id.
    function removeUserFromList(bytes32 userId, string memory listId) external {
        requireMutatePermission();
        delete userLists[listId][userId];
    }

    /// @notice Only root can add delegates. Delegates have mutate permissions.
    /// @param addr is Eth address
    function addDelegate(address addr) external {
        require(msg.sender == root, "Must be root");
        delegates[addr] = true;
    }

    /// @notice Removing delegates is only posible from root or by himself.
    /// @param addr is Eth address
    function removeDelegate(address addr) external {
        require(
            msg.sender == root || msg.sender == addr,
            "Not allowed to remove address"
        );
        delete delegates[addr];
    }

    function requireMutatePermission() private view {
        require(
            msg.sender == root || delegates[msg.sender],
            "Not allowed to mutate"
        );
    }
}

contract Proxy {

function hasPassedKYC(address addr) public view returns (bool) {
    FractalRegistry registry = FractalRegistry(0xa73084a9F71e1A4183Cf7A4Bf3cEDbDF46BeF61E);
    bytes32 fractalId = registry.getFractalId(addr);
    if (fractalId == 0) {
        return false;
    }
        return registry.isUserInList(fractalId, "0bafea9656909fcb14579fe449b8874c46c8b5b3b2cf2c3d9fd5ad834d18fe5c") || registry.isUserInList(fractalId, "4e1d61ab6c70b34a40b5696a36815dae72dcf00d53d16115761002fd8353cb72");
    }
}