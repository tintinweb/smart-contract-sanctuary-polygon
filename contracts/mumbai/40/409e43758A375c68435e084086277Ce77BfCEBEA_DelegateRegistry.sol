/**
 *Submitted for verification at polygonscan.com on 2023-05-23
*/

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.9;

contract DelegateRegistry {
    
    // The first key is the delegator and the second key a id. 
    // The value is the address of the delegate 
    mapping (address => mapping (bytes32 => address[])) public delegation;
    
    // Using these events it is possible to process the events to build up reverse lookups.
    // The indeces allow it to be very partial about how to build this lookup (e.g. only for a specific delegate).
    event SetDelegate(address indexed delegator, bytes32 indexed id, address indexed delegate);
    event ClearDelegate(address indexed delegator, bytes32 indexed id, address indexed delegate);
    event ClearAllDelegates(address indexed delegator, bytes32 indexed id);
    
    /// @dev Sets a delegate for the msg.sender and a specific id.
    ///      The combination of msg.sender and the id can be seen as a unique key.
    /// @param id Id for which the delegate should be set
    /// @param delegate Address of the delegate
    function setDelegate(bytes32 id, address delegate) public {
        require(delegate != msg.sender, "Can't delegate to self");
        require(delegate != address(0), "Can't delegate to 0x0");
        address[] storage currentDelegates = delegation[msg.sender][id];
        bool alreadyDelegated = false;
        for (uint i = 0; i < currentDelegates.length; i++) {
            if (currentDelegates[i] == delegate) {
                alreadyDelegated = true;
                break;
            }
        }
        require(!alreadyDelegated, "Already delegated to this address");

        // Add delegate to the mapping
        currentDelegates.push(delegate);
        delegation[msg.sender][id] = currentDelegates;

        emit SetDelegate(msg.sender, id, delegate);
    }
    
    /// @dev Clears a delegate for the msg.sender and a specific id.
    ///      The combination of msg.sender and the id can be seen as a unique key.
    /// @param id Id for which the delegate should be cleared
    /// @param delegate Address of the delegate to be cleared
    function clearDelegate(bytes32 id, address delegate) public {
        address[] storage currentDelegates = delegation[msg.sender][id];
        uint index = currentDelegates.length;
        for (uint i = 0; i < currentDelegates.length; i++) {
            if (currentDelegates[i] == delegate) {
                index = i;
                break;
            }
        }
        require(index < currentDelegates.length, "Delegate not found");

        // Remove delegate from the mapping
        currentDelegates[index] = currentDelegates[currentDelegates.length - 1];
        currentDelegates.pop();
        //delegation[msg.sender][id] = currentDelegates;

        emit ClearDelegate(msg.sender, id, delegate);
    }
    
    /// @dev Clears all delegates for a specific id of the msg.sender.
    /// @param id Id for which all delegates should be cleared
    function clearAllDelegates(bytes32 id) public {
        address[] storage currentDelegates = delegation[msg.sender][id];
        for (uint i = 0; i < currentDelegates.length; i++) {
            emit ClearDelegate(msg.sender, id, currentDelegates[i]);
        }
        delete delegation[msg.sender][id];
        emit ClearAllDelegates(msg.sender, id);
    }

    /// @dev Returns the number of delegates for a particular id
    /// @param id Id for which to get the number of delegates
    function getTotalDelegates(address delegator, bytes32 id) public view returns (uint) {
        return delegation[delegator][id].length;
    }
}