/**
 *Submitted for verification at polygonscan.com on 2023-05-10
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Calculator {

    function add(uint _x, uint _y) public pure returns(uint){
        return _x + _y;
    }

    function subtract (uint _x, uint _y) public pure returns(uint) {
        return _x - _y;
    }

    function multiplication (uint _x, uint _y) public pure returns(uint) {
        return _x * _y;
    }

    function division (uint _x, uint _y) public pure returns(uint) {
        return _x / _y;
    }
}