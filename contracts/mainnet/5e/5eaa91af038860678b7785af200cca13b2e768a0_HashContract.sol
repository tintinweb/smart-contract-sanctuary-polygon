/**
 *Submitted for verification at polygonscan.com on 2023-04-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HashContract {
    
    mapping(address => bytes32) private userHashes;
    mapping(address => bool) private hashGenerated;
    
    function generateHash(string memory _name, string memory _password, uint256 _birthdate) public view returns(bytes32) {
        require(!hashGenerated[msg.sender], "Hash already generated for this address");
        bytes32 hash = keccak256(abi.encodePacked(_name, _password, _birthdate));
        return hash;
    }
    
    function saveHash(bytes32 hash) public {
        require(!hashGenerated[msg.sender], "Hash already generated for this address");
        userHashes[msg.sender] = hash;
        hashGenerated[msg.sender] = true;
    }
    
    function getHash() public view returns(bytes32) {
        require(hashGenerated[msg.sender], "No hash generated for this address");
        require(msg.sender == address(uint160(uint256(userHashes[msg.sender]))), "Caller cannot access this hash");
        return userHashes[msg.sender];
    }
    
}