/**
 *Submitted for verification at polygonscan.com on 2022-03-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract MyContractA {



uint firstNumber;
uint secondNumber;



constructor (uint _firstNumber, uint _secondNumber) {
firstNumber = _firstNumber;
secondNumber = _secondNumber;
}



function sumNumbers() external view returns(uint) {
return firstNumber + secondNumber;
}
}