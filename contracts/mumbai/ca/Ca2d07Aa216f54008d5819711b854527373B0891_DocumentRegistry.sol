/**
 *Submitted for verification at polygonscan.com on 2023-04-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DocumentRegistry {
    // Struct to represent a document
    struct Document {
        string name;
        string ipfsHash;
    }

    // Mapping to store the documents for each user
    mapping(address => Document[]) public userDocuments;

    // Event emitted when a document is uploaded
    event DocumentUploaded(string name, string ipfsHash);

    // Function to upload a document to IPFS and store the resulting hash in the array
    function uploadDocument(address user, string memory _name, string memory _ipfsHash) public {
    // Create a new Document struct with the name and IPFS hash
    Document memory document = Document({
        name: _name,
        ipfsHash: _ipfsHash
    });

    // Add the new document to the user's array
    userDocuments[user].push(document);

    // Emit the DocumentUploaded event
    emit DocumentUploaded(_name, _ipfsHash);
    }


    // Function to get the total number of uploaded documents for a specific user
    function getDocumentCount(address user) public view returns (uint256) {
        return userDocuments[user].length;
    }

    // Function to get a specific document by index for a specific user
    function getDocument(address user, uint256 index) public view returns (string memory, string memory) {
        // Make sure the index is valid
        require(index < userDocuments[user].length, "Invalid document index");

        // Get the document from the array
        Document memory document = userDocuments[user][index];

        // Return the name and IPFS hash for the document
        return (document.name, document.ipfsHash);
    }

    // Function to get all uploaded documents for a specific user
    function getAllDocuments(address user) public view returns (Document[] memory) {
        return userDocuments[user];
    }
}