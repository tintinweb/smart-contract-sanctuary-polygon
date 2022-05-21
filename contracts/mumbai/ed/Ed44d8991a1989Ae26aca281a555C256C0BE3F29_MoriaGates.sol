// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract MoriaGates {

    event CorrectPassword(bool result);
    bytes32 private _magicPassword;
    //string private _magicPassword;
    
    constructor(string memory magicPassword) {
        _magicPassword = keccak256(abi.encode(magicPassword));
    }
    
    function openGates(string memory password) public {   

        if (keccak256(abi.encode(password)) == _magicPassword)
        {
            emit CorrectPassword(true);
        }
        else
        {
            emit CorrectPassword(false);
        }
    }    
}