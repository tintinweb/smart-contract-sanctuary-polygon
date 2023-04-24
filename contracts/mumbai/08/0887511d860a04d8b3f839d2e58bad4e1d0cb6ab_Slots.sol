/**
 *Submitted for verification at polygonscan.com on 2023-04-24
*/

//SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

contract Slots {

    uint256 public randomNumber;

    struct Commitments {
        uint256 entropy;
        uint256 revealBlock;
    }

    mapping (address => Commitments) commitments;

    // 1. Commit a number on chain. Use as entropy
    function commit(uint256 _entropy) public {
        commitments[msg.sender].entropy = _entropy;
        commitments[msg.sender].revealBlock = block.number;
    }

    // 2. After a few blocks, reveal random number
    function reveal() public {
        require(commitments[msg.sender].revealBlock < block.number, "Reveal too soon");
        require(commitments[msg.sender].entropy != 0, "Must commit");
        uint256 entropy = commitments[msg.sender].entropy;
        // reset commitment
        commitments[msg.sender].revealBlock = 0;
        commitments[msg.sender].entropy = 0;
        // set random number
        randomNumber = uint256(keccak256(abi.encodePacked(
            blockhash(block.number),
            entropy
        )));
    }

}