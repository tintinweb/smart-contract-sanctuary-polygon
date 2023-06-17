// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract ChamberOfSecrets {
    uint256 public totalCoS;
    
    struct CoS {
        string cid;
        uint256 decryptionTime;
        address owner;
        uint256 index;
    }
    
    mapping(uint256 => CoS) public chambers;
        
    event NewCoS(string cid, uint256 indexed decryptionTime, address indexed owner, uint256 indexed index);

    function addCoS(string calldata cid, uint256 decryptionTime) public {
        chambers[totalCoS] = CoS(cid, decryptionTime, msg.sender, ++totalCoS);
        emit NewCoS(cid, decryptionTime, msg.sender, totalCoS);
    }
}