/**
 *Submitted for verification at polygonscan.com on 2023-04-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PasswordHasher {
    
    function hashPassword(string memory _password) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_password));
    }
    
}