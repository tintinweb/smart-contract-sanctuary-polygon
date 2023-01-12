/**
 *Submitted for verification at polygonscan.com on 2023-01-11
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract AccountDelegate {
    mapping(address => address) delegateToOwner;
    mapping(address => address) ownerToDelegate;
    event DelegateChanged(address owner);
    event PermissionsChanged(address owner);

    constructor() {}

    function setDelegateToOwner(address owner, address delegate) public {
      require( delegateToOwner[delegate] == address(0) && ownerToDelegate[owner] == address(0));
        ownerToDelegate[owner] = delegate;
        delegateToOwner[delegate] = owner;
        emit DelegateChanged(owner);
    }

    function deleteDelegate(address owner) public {
        address delegate = ownerToDelegate[owner];
        ownerToDelegate[owner] = address(0);
        delegateToOwner[delegate] = address(0);
        emit DelegateChanged(owner);
    }

    function changePermission(address owner) public {
        emit PermissionsChanged(owner);
    }

    function getOwnerToDelegate(address owner) public view returns (address) {
        return ownerToDelegate[owner];
    }

    function getDelegateToOwner(address delegate)
        public
        view
        returns (address)
    {
        return delegateToOwner[delegate];
    }

    function checkPermission(address delegate)
        public
        view
        returns (bool, address )
    {
        require(
            delegateToOwner[delegate] != address(0),
            "You are not a delegate."
        );
        return (true, delegateToOwner[delegate]);
    }
}