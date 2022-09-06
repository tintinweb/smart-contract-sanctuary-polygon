/**
 *Submitted for verification at polygonscan.com on 2022-09-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleStorage {

    string public savedString;
    
    function updateString(string memory _newString) public {
        savedString = _newString;
    }

    function deleteString() public {
        savedString = "";
    }
}