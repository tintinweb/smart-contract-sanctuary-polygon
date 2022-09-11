/**
 *Submitted for verification at polygonscan.com on 2022-09-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleContract {    
    uint256 private number;
    
    constructor() {
        number = 10;
    }

    function getNumber() view external returns(uint256) {
        return number;
    }
    
    function setNumber(uint256 _num) external  {
        number = _num;
    }
}