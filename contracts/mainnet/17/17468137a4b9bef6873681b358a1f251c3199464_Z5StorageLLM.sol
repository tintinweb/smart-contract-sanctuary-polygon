/**
 *Submitted for verification at polygonscan.com on 2023-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Z5StorageLLM {
    // Mapping from address to data string
    mapping(address => string) public LLMData;

    event DataSaved(address indexed user, string data);

    function saveData(string memory data) public {
        LLMData[msg.sender] = data;
        emit DataSaved(msg.sender, data);
    }
    
    function getData(address user) public view returns (string memory) {
        return LLMData[user];
    }
}