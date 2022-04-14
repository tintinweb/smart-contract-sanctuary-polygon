/**
 *Submitted for verification at polygonscan.com on 2022-04-14
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

contract test{
    mapping(string=>address) orderString;
    mapping(uint=>address) orderInt;

    function test1(string memory str) public {
        orderString[str] = msg.sender;
    }

    function test2(uint ui) public {
        orderInt[ui] = msg.sender;
    }
    
}