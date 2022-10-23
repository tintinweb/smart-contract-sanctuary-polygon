/**
 *Submitted for verification at polygonscan.com on 2022-10-22
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

error InvalidCall();
error InvalidNumber(uint256);

contract Errors {

    uint256 public number;
    
    function normalError() public {
        number = 666;
        revert("InvalidCall()");
    }

    function customError() public {
        number = 666;
        revert InvalidCall();
    }

    function customErrorWithNumber(uint256 _number) public {
        if (number < 666) revert InvalidNumber(number);
        number = _number;
    }

    function setNumber(uint256 _number) public {
        number = _number;
    }
}