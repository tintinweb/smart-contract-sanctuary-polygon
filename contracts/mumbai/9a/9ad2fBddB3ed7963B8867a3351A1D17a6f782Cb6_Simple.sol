/**
 *Submitted for verification at polygonscan.com on 2022-08-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Simple {
    uint number;

    constructor (uint _number)
    {
        number = _number;
    }

    function getNumber()public view returns(uint) {
        return number;
        
    }
}