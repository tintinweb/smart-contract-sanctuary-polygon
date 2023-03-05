/**
 *Submitted for verification at polygonscan.com on 2023-03-04
*/

//SPDX-License-Identifier: UNLICENSED



pragma solidity ^0.8.0;



contract IpfsStorage {
    
    struct File {
        bytes32 name;
        string ipfsHash;
    }
    
    mapping(bytes32 => File[]) files;
    bytes32[] fileNames;
    
    function addFile(bytes32 _name, string memory _ipfsHash) public {
        bool fileExists = false;
        for (uint i = 0; i < fileNames.length; i++) {
            if (fileNames[i] == _name) {
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
    
    function getFilesByName(bytes32 _name) public view returns (string[] memory) {
        uint fileCount = files[_name].length;
        string[] memory ipfsHashes = new string[](fileCount);
        for (uint i = 0; i < fileCount; i++) {
            ipfsHashes[i] = files[_name][i].ipfsHash;
        }
        return ipfsHashes;
    }
    
    function getAllFileNames() public view returns (bytes32[] memory) {
        return fileNames;
    }
}