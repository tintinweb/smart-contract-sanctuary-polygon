/**
 *Submitted for verification at polygonscan.com on 2022-06-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract data{

    struct participant{
        address userId;
        string name;
        string userAddress;
        string date;
        bool isExist;
    }

    struct owner{
        string name;
        string date;
    }

    mapping (address => participant) public participants;
    owner[] owners;

    //Add Participant Function
    function addParticipants(address _userId, string memory _name, string memory _address, string memory _date) public returns (bool){
        participants[_userId] = participant(_userId, _name, _address, _date, true);
        return true;
    }

    //Extra function that will Delete the Participant
    function deleteParticipants(address _userId) public returns (bool){
        participants[_userId].isExist = false;
        return true;
    }

    //Extra Function to check If Participant is Available
    function checkParticipants(address _userId) public view returns(bool){
        return participants[_userId].isExist;
    }

    //Returns the Details of the Specific Participant
    function getParticipants(address _userId) public view returns (address, string memory, string memory, string memory){
        require(participants[_userId].isExist == true, "User Don't Exist");
        return(participants[_userId].userId, participants[_userId].name, participants[_userId].userAddress, participants[_userId].date);
    }  

    //Returns Array of All the Owners
    function checkowners() public view returns (owner[] memory){
        return owners;
    }
}