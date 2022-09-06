/**
 *Submitted for verification at polygonscan.com on 2022-09-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleStorage {

    uint public savedNumber;
    
    function updateNumber(uint _newNumber) public {
        savedNumber = _newNumber;
    }

    function deleteNumber() public {
        savedNumber = 0;
    }
}