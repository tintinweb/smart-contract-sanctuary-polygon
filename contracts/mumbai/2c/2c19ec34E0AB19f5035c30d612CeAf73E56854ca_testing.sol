/**
 *Submitted for verification at polygonscan.com on 2022-06-07
*/

// File: testing_flat.sol


// File: testing.sol

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract testing{
    address public owner_address = msg.sender;
    bytes32 public from_address = keccak256("");
    bytes32 public to_address = keccak256("");
    uint256 public amount = 1;
    bytes32 public hashed_data = keccak256(abi.encodePacked(from_address,to_address,amount));
}