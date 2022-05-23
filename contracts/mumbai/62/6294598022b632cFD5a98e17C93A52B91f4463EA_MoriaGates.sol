// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract MoriaGates {

    event CorrectPassword(bool result, bytes32 inputPassword, bytes32 magicPassword);
    bytes32 private _magicPassword;
    
    constructor(bytes32 magicPassword) {
        _magicPassword = magicPassword;
    }
    
    function openGates(string memory password) public {   

        if (keccak256(abi.encode(password)) == _magicPassword)
        {
            emit CorrectPassword(true, keccak256(abi.encode(password)), _magicPassword);
        }
        else
        {
            emit CorrectPassword(false, keccak256(abi.encode(password)), _magicPassword);
        }
    }    
}