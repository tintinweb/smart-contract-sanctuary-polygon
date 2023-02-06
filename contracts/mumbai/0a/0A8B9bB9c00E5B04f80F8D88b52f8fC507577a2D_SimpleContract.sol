/**
 *Submitted for verification at polygonscan.com on 2023-02-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract SimpleContract {
    
    uint public myValue = 50;
    string public myString = "Hello World!";
    
    function setValue(uint _myValue) public {
        myValue = _myValue;
    }
    
    function setString(string memory _myString) public {
        myString = _myString;
    }    
    
}