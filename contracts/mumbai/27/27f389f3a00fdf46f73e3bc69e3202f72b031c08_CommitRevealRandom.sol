/**
 *Submitted for verification at polygonscan.com on 2022-10-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CommitRevealRandom {
    bytes32 public commitHash;
    uint256 public blockNumber;
    bytes32 public randomNumber;

    // 1. Generate preimage off-chain and create hash
    function hashPreimage(bytes32 _preimage) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(_preimage));
    }

    // 2. Commit hash on chain
    function commit(bytes32 _commitHash) public {
        blockNumber = block.number;
        commitHash = _commitHash;
    }

    // 3. After a few blocks, reveal image
    function reveal(bytes32 _preimage) public {
        require(block.number > blockNumber, "Must wait a few block to reveal");
        require(commitHash == keccak256(abi.encodePacked(_preimage)), "Hashing preimage must match commit hash");
        // 4. Use preimage from past and block hash from future to generate random number
        randomNumber = keccak256(abi.encodePacked(_preimage, blockhash(block.number)));
    }


}