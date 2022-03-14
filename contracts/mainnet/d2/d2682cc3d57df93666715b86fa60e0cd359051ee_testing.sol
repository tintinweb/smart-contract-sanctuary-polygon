/**
 *Submitted for verification at polygonscan.com on 2022-03-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract testing {

    uint256 public theNumber;
    uint256 public secondNumber;
    event numberSet(uint256 number);


    function setNumber(uint256 _number) public {
        theNumber = _number;
        emit numberSet(_number);
    }

    function react(uint256 _secondNumber) public {
        secondNumber = _secondNumber;
    }
}