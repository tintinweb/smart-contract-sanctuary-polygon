/**
 *Submitted for verification at polygonscan.com on 2023-04-27
*/

// SPDX-License-Identifier: MIT

// Istanbul BTC
// Istanbul University Faculty of Economics
// Blockchain Tecnologies and Innovation Center

// Emre Akadal - [email protected]

pragma solidity ^0.8.0;

contract Certification {

    struct Document {
        string documentType;
        string eventName;
        string documentDate;
    }

    mapping(bytes32 => Document[]) private documents;
    address[] private owners;

    modifier onlyOwner {
        require(isOwner(msg.sender), "Only owners can call this function.");
        _;
    }

    constructor() {
        owners.push(msg.sender);
    }

    function isOwner(address _address) public view returns (bool) {
        for (uint i = 0; i < owners.length; i++) {
            if (_address == owners[i]) {
                return true;
            }
        }
        return false;
    }

    function addOwner(address _address) public onlyOwner {
        require(!isOwner(_address), "Address is already an owner.");
        owners.push(_address);
    }

    function removeOwner(address _address) public onlyOwner {
        require(isOwner(_address), "Address is not an owner.");
        for (uint i = 0; i < owners.length; i++) {
            if (_address == owners[i]) {
                owners[i] = owners[owners.length - 1];
                owners.pop();
                return;
            }
        }
    }

    function addDocument(
        string memory _documentType,
        string memory _eventName,
        string memory _documentDate,
        bytes32 _fingerPrint
    ) public onlyOwner {
        Document memory newDocument = Document({
            documentType: _documentType,
            eventName: _eventName,
            documentDate: _documentDate
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