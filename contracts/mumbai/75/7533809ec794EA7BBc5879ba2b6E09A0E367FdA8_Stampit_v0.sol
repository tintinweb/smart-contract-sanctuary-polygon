/**
 *Submitted for verification at polygonscan.com on 2023-06-28
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract Stampit_v0 {
    struct Stamp {
        string file_hash;
        string meta_hash;
    }

    Stamp[] stamps;
    uint256 public version;
    uint256 n_stamps;
    address owner;

    event NewStampCreated(string stampIndex, string fileHash, string metaHash);

    constructor() {
        owner = msg.sender;
        version = 0;
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function newStamp(string memory file_hash, string memory meta_hash) public {
        require(owner == msg.sender, 'Only the contract owner can create stamps');
        string memory index = string(abi.encodePacked(uint2str(version), "-", uint2str(n_stamps)));
        emit NewStampCreated(index, file_hash, meta_hash);
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