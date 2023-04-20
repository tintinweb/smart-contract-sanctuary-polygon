/**
 *Submitted for verification at polygonscan.com on 2023-04-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EducationCertification {

    struct Document {
        string documentType;
        string eventName;
        string documentDate;
        string fullName;
        bytes32 fullNameHash;
    }

    mapping(bytes32 => Document[]) private documents;
    address private owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function addDocument(
        string memory _documentType,
        string memory _eventName,
        string memory _documentDate,
        string memory _firstName,
        string memory _lastName
    ) public onlyOwner {
        string memory fullName = string(abi.encodePacked(_firstName, " ", _lastName));
        bytes32 fullNameHash = keccak256(abi.encodePacked(fullName));

        Document memory newDocument = Document({
            documentType: _documentType,
            eventName: _eventName,
            documentDate: _documentDate,
            fullName: fullName,
            fullNameHash: fullNameHash
        });

        documents[fullNameHash].push(newDocument);
    }

    function verifyDocument(
        string memory _firstName,
        string memory _lastName
    ) public view returns (Document[] memory) {
        bytes32 fullNameHash = keccak256(abi.encodePacked(string(abi.encodePacked(_firstName, " ", _lastName))));
        Document[] memory personDocuments = documents[fullNameHash];

        require(personDocuments.length > 0, "No documents found for this person.");

        return personDocuments;
    }
}