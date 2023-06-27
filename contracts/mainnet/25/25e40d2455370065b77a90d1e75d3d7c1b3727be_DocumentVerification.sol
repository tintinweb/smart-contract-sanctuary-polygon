/**
 *Submitted for verification at polygonscan.com on 2023-06-27
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: Unlicensed

contract DocumentVerification {
    struct Document {
        string hashes;
        string issuedBy;
        string issuedTo;
    }

    Document[] public documents;

    event CreatedDocument(
        string hashes,
        string issuedBy,
        string issuedTo,
        uint256 createTime
    );

    mapping(string => bool) private verifiedHashes;
    mapping(string => bool) private documentHashes;

    function UploadMultipleHashes(
        string[] memory hashes,
        string memory issuedBy,
        string memory issuedTo
    ) external {
        require(hashes.length > 0, "Hashes array cannot be empty");

        for (uint256 i = 0; i < hashes.length; i++) {
            string memory hash = hashes[i];
            require(bytes(hash).length > 0, "Hash cannot be empty");

            require(!documentHashes[hash], "Duplicate hash found");

            Document memory newDocument = Document(hash, issuedBy, issuedTo);
            documents.push(newDocument);
            documentHashes[hash] = true;
            verifiedHashes[hash] = true;
            emit CreatedDocument(hash, issuedBy, issuedTo, block.timestamp);
        }
    }

    function getDocument(string memory hash)
        external
        view
        returns (Document memory)
    {
        for (uint256 i = 0; i < documents.length; i++) {
            if (keccak256(bytes(documents[i].hashes)) == keccak256(bytes(hash))) {
                return documents[i];
            }
        }
        revert("Document not found");
    }

    function verifyHash(string memory hash) external view returns (bool) {
        return verifiedHashes[hash];
    }

    function verifyMultipleHashes(string[] memory hashes)
        external
        view
        returns (bool[] memory)
    {
        bool[] memory verificationResults = new bool[](hashes.length);
        for (uint256 i = 0; i < hashes.length; i++) {
            verificationResults[i] = verifiedHashes[hashes[i]];
        }
        return verificationResults;
    }
}