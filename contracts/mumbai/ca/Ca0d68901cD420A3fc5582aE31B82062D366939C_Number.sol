/**
 *Submitted for verification at polygonscan.com on 2022-06-17
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract Number {
    uint256 private number;

    constructor(uint256 _number){
        number = _number;
    }

    function setNumber(uint256 _number) public {
        number = _number;
    }

    function getNumber() public view returns(uint256) {
        return number;
    }
}