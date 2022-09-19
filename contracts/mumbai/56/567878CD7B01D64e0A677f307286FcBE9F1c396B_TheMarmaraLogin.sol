// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract TheMarmaraLogin {

    event CorrectPassword(bool result);
    bytes32 private _password;

    address owner;
    
    constructor(bytes32 password) {
        _password = password;
        owner = msg.sender;
    }
    
    function openGates(string memory password) public {   

        //DISCLAIMER -- NOT PRODUCTION READY CONTRACT
        //require(msg.sender == owner);

        if (hash(password) == _password)
        {
            emit CorrectPassword(true);
        }
        else
        {
            emit CorrectPassword(false);
        }
    }   

    function hash(string memory stringValue) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(stringValue));
    } 
}