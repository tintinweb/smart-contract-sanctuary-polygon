/**
 *Submitted for verification at polygonscan.com on 2022-02-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.11;

contract HelloWorld {
    string public greeting = 'hello world!';

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }
}