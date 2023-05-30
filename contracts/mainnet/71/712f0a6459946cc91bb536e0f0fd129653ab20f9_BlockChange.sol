/**
 *Submitted for verification at polygonscan.com on 2023-05-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;
contract BlockChange {

    event SayHello(string str);

    function say(string memory str) public {
        emit SayHello(str);
    }
}