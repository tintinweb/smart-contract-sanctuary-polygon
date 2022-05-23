// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract MoriaGates {

    event CorrectPassword(bool result, string inputPassword, bytes32 hashedInputPassword, bytes32 magicPassword);
    bytes32 private _magicPassword;
    
    constructor(bytes32 magicPassword) {
        _magicPassword = magicPassword;
    }
    
    function openGates(string memory password) public {   

        if (keccak256(abi.encode(password)) == _magicPassword)
        {
            emit CorrectPassword(true, password, keccak256(abi.encodePacked(password)), _magicPassword);
        }
        else
        {
            emit CorrectPassword(false, password, keccak256(abi.encodePacked(password)), _magicPassword);
        }
    }    
}