// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Document {
    mapping (bytes32 => uint256) private documentTimestamps;
    mapping (uint256 => bytes32) private documentHashes;

    event DocumentStored(uint256 indexed documentId, bytes32 documentHash, uint256 timestamp);

    function storeDocumentHash(uint256 documentId, bytes32 documentHash) external {
        require(documentTimestamps[documentHash] == 0, "Document hash already exists");
        uint256 timestamp = block.timestamp;
        documentTimestamps[documentHash] = timestamp;
        documentHashes[documentId] = documentHash;
        emit DocumentStored(documentId, documentHash, timestamp);
    }

    function getDocumentTimestamp(bytes32 documentHash) external view returns (uint256) {
        return documentTimestamps[documentHash];
    }

    function getFileHash(uint256 documentId) external view returns (bytes32) {
        return documentHashes[documentId];
    }
}