/**
 *Submitted for verification at polygonscan.com on 2023-02-03
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract FileHash {
    string public fileHash;

    function setHash(string memory _hash) public {
        fileHash = _hash;
    }

    function getHash() public view returns (string memory) {
        return fileHash;
    }
}