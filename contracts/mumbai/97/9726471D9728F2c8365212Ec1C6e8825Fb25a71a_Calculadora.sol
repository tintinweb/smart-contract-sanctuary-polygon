// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
                 
contract Calculadora {
     function suma(uint a, uint b) public pure returns(uint){
        return a + b;
    }

    function resta(uint a, uint b) public pure returns(uint){
        return a - b;
    }

    function multiplica(uint a, uint b) public pure returns(uint){
        return a * b;
    }

    function divide(uint a, uint b) public pure returns(uint){
        return a / b;
    }
}