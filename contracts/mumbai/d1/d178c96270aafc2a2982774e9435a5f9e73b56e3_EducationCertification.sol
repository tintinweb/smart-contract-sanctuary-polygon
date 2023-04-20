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
        bytes32 fingerPrint;
        uint256 timestamp;
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
        bytes32 _fingerPrint
    ) public onlyOwner {
        //string memory _hash = string(abi.encodePacked(_firstName, _lastName, _validationNumber));
        //bytes32 fingerPrint = keccak256(abi.encodePacked(_hash));

        Document memory newDocument = Document({
            documentType: _documentType,
            eventName: _eventName,
            documentDate: _documentDate,
            fingerPrint: _fingerPrint,
            timestamp: block.timestamp
        });

        documents[_fingerPrint].push(newDocument);
    }

    function verifyDocument(
        string memory _firstName,
        string memory _lastName,
        string memory _validationNumber
    ) public view returns (Document[] memory) {
        bytes32 fingerPrint = keccak256(abi.encodePacked(string(abi.encodePacked(_firstName, _lastName, _validationNumber))));
        Document[] memory personDocuments = documents[fingerPrint];

        require(personDocuments.length > 0, "No documents found!");

        return personDocuments;
    }

    function calculateFingerPrint(
        string memory _firstName,
        string memory _lastName,
        string memory _validationNumber
    ) public pure returns (bytes32) {
        bytes32 fingerPrint = keccak256(abi.encodePacked(_firstName, _lastName, _validationNumber));
        return fingerPrint;
    }

}