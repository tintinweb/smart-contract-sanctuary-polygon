/**
 *Submitted for verification at polygonscan.com on 2023-06-21
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract Stampit_v0 {
    struct Stamp {
        string file_hash;
        string meta_hash;
    }

    Stamp[] stamps;
    uint256 n_stamps;
    address owner;

    event NewStampCreated(uint256 indexed stampIndex, string fileHash, string metaHash);

    constructor() {
        owner = msg.sender;
    }

    function newStamp(string memory file_hash, string memory meta_hash) public {
        require(owner == msg.sender, 'Only the contract owner can create stamps');
        emit NewStampCreated(n_stamps, file_hash, meta_hash);
        n_stamps++;
        stamps.push(Stamp(file_hash, meta_hash));
    }

    function auditStampDocument(uint256 n_stamp, string memory file_hash) public view returns (bool) {
        require(n_stamp < n_stamps, 'Invalid stamp number');
        Stamp memory stamp = stamps[n_stamp];
        return (keccak256(bytes(stamp.file_hash)) == keccak256(bytes(file_hash)));
    }

    function auditStampMetadata(uint256 n_stamp, string memory meta_hash) public view returns (bool) {
        require(n_stamp < n_stamps, 'Invalid stamp number');
        Stamp memory stamp = stamps[n_stamp];
        return (keccak256(bytes(stamp.meta_hash)) == keccak256(bytes(meta_hash)));
    }
}