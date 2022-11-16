/**
 *Submitted for verification at polygonscan.com on 2022-11-15
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

contract IDRegistry {

    error InvalidParameter();
    error Unauthorized();

    mapping(string => bool) public isRegistered;

    event IDAdded(string indexed _newID);
    event IDsAdded(string[] _newIDs);
    event IDRemoved(string indexed _removedID);
    event IDsRemoved(string[] _removedIDs);

    /*
    function initialize() initializer external {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }
    */

    function addID(string memory _newID) external {
        isRegistered[_newID] = true;
        emit IDAdded(_newID);
    }

    function addIDs(string [] memory _newIDs) external {
        if (_newIDs.length > 100) revert InvalidParameter();
        for(uint i = 0; i < _newIDs.length; i++)
            isRegistered[_newIDs[i]] = true;
        emit IDsAdded(_newIDs);
    }

    function removeID(string memory _removedID) external {
        isRegistered[_removedID] = false;
        emit IDRemoved(_removedID);
    }

    function removeIDs(string [] memory _toBeRemovedIDs) external {
        if (_toBeRemovedIDs.length > 100) revert InvalidParameter();
        for(uint i = 0; i < _toBeRemovedIDs.length; i++)
            isRegistered[_toBeRemovedIDs[i]] = false;
        emit IDsRemoved(_toBeRemovedIDs);
    }

    /*
    function revokeRole(bytes32 role, address) public virtual override {
        if (role == DEFAULT_ADMIN_ROLE) revert InvalidParameter();
    }

    function renounceRole(bytes32 role, address) public virtual override {
        if (role == DEFAULT_ADMIN_ROLE) revert InvalidParameter();
    }

    function _authorizeUpgrade(address) internal view override {
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) revert Unauthorized();
    }
    */
}