// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EmailStorageContract {
    mapping(address => bytes32) private contentMapping;
    
    // Function to store content
    function storeContent(bytes32 contentHash) public {
        contentMapping[msg.sender] = contentHash;
    }
    
    // Function to retrieve content
    function retrieveContent() public view returns (bytes32) {
        require(contentMapping[msg.sender] != 0, "No content found for the caller");
        return contentMapping[msg.sender];
    }
}