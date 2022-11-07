/**
 *Submitted for verification at polygonscan.com on 2022-11-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Random {
    uint8 public rand_num;

    function Generate_Number() public returns (uint8) {
        bytes32 hash = blockhash(block.number);
        uint256 randomNumber = uint256(
            keccak256(abi.encodePacked(block.timestamp, hash, msg.sender))
        );
        rand_num = uint8((randomNumber % 10) + 1);
        return rand_num;
    }
}