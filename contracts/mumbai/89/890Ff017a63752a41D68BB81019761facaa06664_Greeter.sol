/**
 *Submitted for verification at polygonscan.com on 2022-05-25
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Greeter {
    string public test;

    constructor(string memory _test) {
        test = _test;
    }

    function setGreeting(string memory _test) public {
        test = _test;
    }
}