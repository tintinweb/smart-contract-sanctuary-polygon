/**
 *Submitted for verification at polygonscan.com on 2023-05-04
*/

/**
 *Submitted for verification at Etherscan.io on 2023-05-03
*/

// SPDX-License-Identifier: UNLICENSED 
pragma solidity ^0.8.19;

contract IPFS {

    address public manager;
    struct File {
        uint FileID;
        string name;
        string currentCompany;
        uint256 experienceYears;
        string pinataHash;
    }

    mapping (uint => File) fileID;
 constructor()
 {
     manager=msg.sender;
 }
    function sendHash(uint _id,string memory _name, string memory _currentCompany, uint256 _experienceYears, string memory _pinataHash) public {
        require(msg.sender==manager);
        fileID[_id] = File({
            FileID:_id,
            name: _name,
            currentCompany: _currentCompany,
            experienceYears: _experienceYears,
            pinataHash: _pinataHash
        });
    }

    function getFile(uint id) public view returns ( uint256 ,string memory, string memory, uint256, string memory) {
       File memory file = fileID[id];
        return (file.FileID,file.name, file.currentCompany, file.experienceYears, file.pinataHash);
    }

}