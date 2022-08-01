/**
 *Submitted for verification at polygonscan.com on 2022-07-31
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract Payment {
    mapping(bytes32 => address) public userIDToAddress;
    mapping(address => bytes32) public addressToUserID;
    mapping(address => bool) public isSubscribed;
    function subscribe(bytes32 _userIdHash) public {
        userIDToAddress[_userIdHash] = msg.sender;
        addressToUserID[msg.sender] = _userIdHash;
        isSubscribed[msg.sender] = true;
    }

    function checkID(address _user) public view returns (bytes32)
    {
        return addressToUserID[_user];
    }

    function checkAddress(bytes32 _UserID) public view returns (address)
    {
        return userIDToAddress[_UserID];
    }

    function checkIsSubscribed(bytes32 _UserID) public view returns (bool){
        return isSubscribed[userIDToAddress[_UserID]];
    }
}