// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract ChamberOfSecrets {
    mapping(address => uint256) public nonces;
    
    event CoS(string cid, uint256 indexed decryptionTime, address indexed owner, uint256 nonce);
    
    function cos(string calldata cid, uint256 decryptionTime) public {
        emit CoS(cid, decryptionTime, msg.sender, ++nonces[msg.sender]);
    }
    
    function getNonce(address owner) public view returns (uint256){
        return nonces[owner];
    }
}