/**
 *Submitted for verification at polygonscan.com on 2023-05-19
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

    function newStamp(string memory file_hash, string memory meta_hash) public returns (uint256) {
        n_stamps++;
        stamps.push(Stamp(file_hash, meta_hash));
        return n_stamps;
    }

    function verifyStamp(uint256 n_stamp, string memory file_hash, string memory meta_hash) public view returns (bool) {
        require(n_stamp < n_stamps, "Invalid stamp number");
        Stamp memory stamp = stamps[n_stamp];
        return (keccak256(bytes(stamp.file_hash)) == keccak256(bytes(file_hash))) &&
               (keccak256(bytes(stamp.meta_hash)) == keccak256(bytes(meta_hash)));
    }
}