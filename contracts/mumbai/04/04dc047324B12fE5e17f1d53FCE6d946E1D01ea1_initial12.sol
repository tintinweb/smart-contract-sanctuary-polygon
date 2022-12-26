/**
 *Submitted for verification at polygonscan.com on 2022-12-25
*/

// Solidity program to implement
// the above approach
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;
  
contract initial12
{
    string public message = "Hello World";
  
    function setMessage(string memory _newMessage) public 
    {
        message = _newMessage;
    }
}