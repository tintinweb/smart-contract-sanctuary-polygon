// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Document {
    mapping (bytes32 => uint256) private documentTimestamps;

    event DocumentStored(bytes32 indexed documentHash, uint256 timestamp);

    function storeDocumentHash(bytes32 documentHash) external {
        require(documentTimestamps[documentHash] == 0, "Document hash already exists");
        uint256 timestamp = block.timestamp;
        documentTimestamps[documentHash] = timestamp;
        emit DocumentStored(documentHash, timestamp);
    }

    function getDocumentTimestamp(bytes32 documentHash) external view returns (uint256) {
        return documentTimestamps[documentHash];
    }
}