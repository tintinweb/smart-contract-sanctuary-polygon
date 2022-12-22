/**
 *Submitted for verification at polygonscan.com on 2022-12-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BasicContract {
    //a variable for storing numbers
    uint256 number;
    //function for storing a number
    function storeNumber(uint256 _number) public {
        number = _number;
    }
    //function for reading the number
    function readNumber() public view returns (uint256) {
        return number;
    }
}