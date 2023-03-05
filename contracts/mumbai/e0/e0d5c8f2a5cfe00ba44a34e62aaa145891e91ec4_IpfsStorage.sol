/**
 *Submitted for verification at polygonscan.com on 2023-03-04
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract IpfsStorage {
    address private owner;
    
    struct File {
        string name;
        string ipfsHash;
    }
    
    mapping(string => File[]) files;
    string[] fileNames;
    
    constructor() {
        owner = msg.sender;
    }
    
    function addFile(string memory _name, string memory _ipfsHash) public {
        require(msg.sender == owner, "Only the owner can add a file.");
        
        bool fileExists = false;
        for (uint i = 0; i < fileNames.length; i++) {
            if (keccak256(bytes(fileNames[i])) == keccak256(bytes(_name))) {
                files[_name].push(File(_name, _ipfsHash));
                fileExists = true;
                break;
            }
        }
        if (!fileExists) {
            files[_name].push(File(_name, _ipfsHash));
            fileNames.push(_name);
        }
    }
    
    function getFilesByName(string memory _name) public view returns (string[] memory) {
        uint fileCount = files[_name].length;
        string[] memory ipfsHashes = new string[](fileCount);
        for (uint i = 0; i < fileCount; i++) {
            ipfsHashes[i] = files[_name][i].ipfsHash;
        }
        return ipfsHashes;
    }
    
    function getAllFileNames() public view returns (string[] memory) {
        return fileNames;
    }
}