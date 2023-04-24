/**
 *Submitted for verification at polygonscan.com on 2023-04-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DocumentVerification {

    struct Document {
        address owner;
        bytes32 documentHash;
        bool verified;
    }
    
    mapping (uint256 => Document) public documents;
    uint256 public documentCount;

    function uploadDocument(bytes32 _documentHash) public {
        documents[documentCount] = Document(msg.sender, _documentHash, false);
        documentCount++;
    }

    function verifyDocument(uint256 _documentId, bytes32 _documentHash) public {
        require(documentCount>=_documentId && _documentId>0,"Does not exist");
        Document storage document = documents[_documentId-1];
        require(document.owner == msg.sender, "You are not the owner of this document.");
        require(document.verified==false,"document is already verified");
        require(document.documentHash == _documentHash, "The document hash does not match the one on file.");
        document.verified = true;
       
    }

   
}