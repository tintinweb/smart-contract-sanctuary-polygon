/**
 *Submitted for verification at polygonscan.com on 2022-09-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
contract myfirstcontract {
    // developed by sonam
    function multiply (uint _input1, uint _input2) public pure returns (uint _output) {
        uint output = _input1 * _input2 ; 
        return output ;

    }
    function addition (uint _input1, uint _input2) public pure returns (uint _output) {
        uint output = _input1 + _input2 ; 
        return output;
    }
    function developername () public pure returns (string memory name){
        return "sonam";
    }
}