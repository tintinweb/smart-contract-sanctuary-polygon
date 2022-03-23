/**
 *Submitted for verification at polygonscan.com on 2022-03-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.8.13;

contract ProofOfExistence {

    bytes32 public proof;
    address public uploadedBy;

    constructor(bytes32 fileHash) {
        proof = fileHash;
        uploadedBy = msg.sender;
    }
    
}