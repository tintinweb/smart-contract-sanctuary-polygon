// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract LicensAccountContract{
    
    mapping(address => string) public creatorCID;
    event CreatorUpdated(
        address creator,
        string creatorCID
    );
    constructor(){}
    function updateCreator(string memory _creatorCID) external {
        creatorCID[msg.sender] = _creatorCID;
        emit CreatorUpdated(msg.sender, _creatorCID);
    }
    function isRegistered(address _address) external view returns(bool){
        return bytes(creatorCID[_address]).length != 0;
    }
}