/**
 *Submitted for verification at polygonscan.com on 2023-01-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.17 <0.8.18;

contract ElectronicSignature {

    enum Status {DRAFT, IN_PROGRESS, OK, ARCHIVED}
    uint docId = 1;
    uint signerId = 1;
    address owner;

    struct Signer {
        uint id;
        address addr;
        string fname;
        string lname;
    }
    
    struct Document {
        uint id;
        address owner;
        string content;
        Status status;
        uint createdAt;
        uint updatedAt;
    }

    mapping(uint => Document) documents;
    mapping(uint => Signer) signatures;


    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner(uint _id) {
        require(documents[_id].owner == msg.sender, "Forbidden");
        _;
    }

    modifier onlySigners(uint _id) {
        require(signatures[_id].addr == msg.sender, "Forbidden");
        _;
    }

    modifier documentCanBeSigned(uint _id) {
        require(documents[_id].status == Status.IN_PROGRESS, "Document cannot be signed");
        _;
    }

    function createDocument(string memory _content) public returns (bool) {
        Document memory doc = Document(docId, msg.sender, _content, Status.DRAFT, block.timestamp, block.timestamp);
        documents[docId] = doc;
        docId += 1;
        return true;
    }

    function showDocument(uint _docId) public view onlyOwner(_docId) returns (Document memory) {
        return documents[_docId];
    }

    function editDocument(uint _docId, string memory _content) public onlyOwner(_docId) returns (Document memory) {
        documents[_docId].updatedAt = block.timestamp;
        documents[_docId].content = _content;

        return documents[_docId];
    }

    function setStatusDocumentDraft(uint _docId) public onlyOwner(_docId) returns (Document memory) {
        documents[_docId].updatedAt = block.timestamp;
        documents[_docId].status = Status.DRAFT;

        return documents[_docId];
    }

    function setStatusDocumentInProgress(uint _docId) public onlyOwner(_docId) returns (Document memory) {
        documents[_docId].updatedAt = block.timestamp;
        documents[_docId].status = Status.IN_PROGRESS;

        return documents[_docId];
    }

    function setStatusDocumentOK(uint _docId) public onlyOwner(_docId) returns (Document memory) {
        documents[_docId].updatedAt = block.timestamp;
        documents[_docId].status = Status.OK;

        return documents[_docId];
    }

    function setStatusDocumentArchived(uint _docId) public onlyOwner(_docId) returns (Document memory) {
        documents[_docId].updatedAt = block.timestamp;
        documents[_docId].status = Status.ARCHIVED;

        return documents[_docId];
    }

    function signDocument(uint _docId) public documentCanBeSigned(_docId) returns(Document memory) {

        return documents[_docId];
    }
}