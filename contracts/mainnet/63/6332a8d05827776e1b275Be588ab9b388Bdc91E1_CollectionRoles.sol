/**
 *Submitted for verification at polygonscan.com on 2023-05-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CollectionRoles {
    address public admin;
    mapping(address => bool) public collectionCreators;
    address[] public collectionCreatorAddresses;

    event RoleGranted(bytes32 indexed role, address indexed account);

    constructor() {
        admin = msg.sender;
        collectionCreators[msg.sender] = true;
        collectionCreatorAddresses.push(msg.sender);

        emit RoleGranted("ADMIN_ROLE", msg.sender);
        emit RoleGranted("COLLECTION_CREATOR_ROLE", msg.sender);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Caller is not an admin");
        _;
    }

    modifier onlyCollectionCreator() {
        require(collectionCreators[msg.sender], "Caller is not a collection creator");
        _;
    }

    function grantAdminRole(address account) public onlyAdmin {
        admin = account;
        emit RoleGranted("ADMIN_ROLE", account);
    }

    function grantCollectionCreatorRole(address account) public onlyAdmin {
        if (!collectionCreators[account]) {
            collectionCreators[account] = true;
            collectionCreatorAddresses.push(account);
            emit RoleGranted("COLLECTION_CREATOR_ROLE", account);
        }
    }

    function revokeCollectionCreatorRole(address account) public onlyAdmin {
        collectionCreators[account] = false;
    }

    function transferOwnership(address newOwner) public onlyAdmin {
        require(newOwner != address(0), "Invalid new owner");
        admin = newOwner;
        collectionCreators[msg.sender] = false;
        collectionCreators[newOwner] = true;
    }

    function getCollectionCreatorAddresses(uint256 startIndex, uint256 pageSize) public view returns (address[] memory) {
    require(startIndex < collectionCreatorAddresses.length, "Invalid start index");
    
    uint256 endIndex = startIndex + pageSize;
    if (endIndex > collectionCreatorAddresses.length) {
        endIndex = collectionCreatorAddresses.length;
    }
    
    uint256 resultSize = endIndex - startIndex;
    address[] memory result = new address[](resultSize);
    
    for (uint256 i = 0; i < resultSize; i++) {
        result[i] = collectionCreatorAddresses[startIndex + i];
    }
    
    return result;
    }
}