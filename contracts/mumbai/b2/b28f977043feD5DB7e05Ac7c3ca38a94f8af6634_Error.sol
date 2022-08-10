// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Error {
    uint public a;

    error ZeroError(string nameError );
    
    function setA(uint _a) public {
        if(_a == 0){
            revert ZeroError("Hello");
        }
        a = _a;
    }
}