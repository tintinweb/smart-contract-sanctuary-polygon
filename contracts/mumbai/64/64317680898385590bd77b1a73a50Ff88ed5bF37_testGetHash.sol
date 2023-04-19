/**
 *Submitted for verification at polygonscan.com on 2023-04-18
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

contract testGetHash {
    uint256 ctr = 1;
    uint256 public blockNumber;
    bytes32 public blockHashNow;

    function proceso()
        public
        returns (
            uint256,
            address,
            bytes4,
            bytes32
        )
    {
        ctr++;
        blockNumber = block.number;
        blockHashNow = blockhash(blockNumber);
        return (blockNumber, tx.origin, msg.sig, blockHashNow);
    }

    function checkBlock(uint256 _b) public returns (bytes32) {
        blockHashNow = blockhash(_b);
        return (blockHashNow);
    }
}