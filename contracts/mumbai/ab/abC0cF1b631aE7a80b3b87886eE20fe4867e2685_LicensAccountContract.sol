// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract LicensAccountContract{
    
    mapping(address => string) public creatorCID;
    event CreatorUpdated(
        address creator,
        string creatorCID
    );
    constructor(){}

    function updateCreator(address _creator, string memory _creatorCID) external {
        creatorCID[_creator] = _creatorCID;
        emit CreatorUpdated(_creator, _creatorCID);
    }
    
    function isRegistered(address _address) external view returns(bool){
        return bytes(creatorCID[_address]).length != 0;
    }
}