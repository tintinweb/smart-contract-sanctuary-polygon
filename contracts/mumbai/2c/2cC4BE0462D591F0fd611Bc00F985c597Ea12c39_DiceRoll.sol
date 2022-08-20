// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract DiceRoll {

    event CorrectNumber(bool result);
    int32 private _magicNumber;

    address owner;
    
    constructor(int32 magicNumber) {
        _magicNumber = magicNumber;
        owner = msg.sender;
    }
    
    function checkDice(int32 diceNumber) public {   

        //DISCLAIMER -- NOT PRODUCTION READY CONTRACT
        //require(msg.sender == owner);

        if (diceNumber == _magicNumber)
        {
            emit CorrectNumber(true);
        }
        else
        {
            emit CorrectNumber(false);
        }
    }   
}