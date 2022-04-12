/**
 *Submitted for verification at polygonscan.com on 2022-04-11
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract FileHash {
    mapping(bytes32 => bool) public document;

    event Notarization(bytes32 hash);

    function notarize(bytes32 hash) public {
        document[hash] = true;
        emit Notarization(hash);
    }
    function notarizeQuick(bytes32 hash) public {
        emit Notarization(hash);
    }
}