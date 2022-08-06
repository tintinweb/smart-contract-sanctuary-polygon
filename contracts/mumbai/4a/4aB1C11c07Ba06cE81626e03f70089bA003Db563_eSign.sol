// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.14;

contract eSign {

    address owner;

    constructor() {
        owner = msg.sender;
    }

    struct SignDocument{
        uint docID;
        address sender;
        address reciever;
        string hash;
        string signature;
    }

    mapping(address=> mapping(uint => SignDocument)) private idToDocument;

    event DocumentCreated (
        uint docID,
        address indexed sender,
        address indexed reciever,
        string hash,
        string signature
    );

    function storeDocumentInfo(uint _docId, address _sender, address _reciever, string memory _hash, string memory _signature) public returns(bool) {
        idToDocument[_sender][_docId] = SignDocument(
            _docId,
            _sender,
            _reciever,
            _hash,
            _signature
        );

        emit DocumentCreated (
        _docId,
        _sender,
        _reciever,
        _hash,
        _signature
        );

        return true;
    }

    function getDocumentInfo(uint _docId, address _sender) public view returns (SignDocument memory) {

        SignDocument storage currentItem = idToDocument[_sender][_docId];

        return currentItem;

    }
}