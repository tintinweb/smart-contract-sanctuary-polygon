// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract PondsMasterContract{
    
    mapping(address => string) public creatorCID;
    event CreatorRegistered(
        address creator,
        string creatorCID
    );
    constructor(){}
    function updateCreator(string memory hash) external {
        creatorCID[msg.sender] = hash;
    }
    function isRegistered(address _address) external view returns(bool){
        return bytes(creatorCID[_address]).length != 0;
    }
}