/**
 *Submitted for verification at polygonscan.com on 2022-07-14
*/

/**
 *Submitted for verification at polygonscan.com on 2022-07-14
*/

/* Copyright (c) 2020 PowerLoom, Inc. */

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

contract AuditRecordStore {
    struct PayloadRecord {
        string ipfsCid;
        uint256 timestamp;
    }

    event RecordAppended(bytes32 apiKeyHash, string snapshotCid, string payloadCommitId, uint256 tentativeBlockHeight, string projectId, uint256 indexed timestamp);

    mapping(bytes32 => PayloadRecord[]) private apiKeyHashToRecords;


    constructor() public {

    }

    function commitRecord(string memory snapshotCid, string memory payloadCommitId, uint256 tentativeBlockHeight, string memory projectId, bytes32 apiKeyHash) public {
        PayloadRecord memory a = PayloadRecord(payloadCommitId, now);
        apiKeyHashToRecords[apiKeyHash].push(a);
        emit RecordAppended(apiKeyHash, snapshotCid, payloadCommitId, tentativeBlockHeight, projectId, now);
    }

    /*
    function getTokenRecordLogs(bytes32 tokenHash) public view returns (PayloadRecord[] memory recordLogs) {
        return tokenHashesToRecords[tokenHash];
    }
    */
}