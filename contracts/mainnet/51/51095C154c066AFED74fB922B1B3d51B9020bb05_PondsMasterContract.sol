// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract PondsMasterContract{
    
    mapping(address => bytes32) public creatorHash;
    event CreatorRegistered(
        address creator,
        bytes32 creatorHash
    );
    constructor(){}
    function registerCreator(bytes32 hash) external {
        require(creatorHash[msg.sender] == bytes32(0),"Already registered");
        creatorHash[msg.sender] = hash;
    }
    function isRegistered(address _address) external view returns(bool){
        return creatorHash[_address] != bytes32(0);
    }
}