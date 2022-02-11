/**
 *Submitted for verification at polygonscan.com on 2022-02-11
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Greeter {
    event HelloWorld(address indexed _from, string indexed message);

    constructor() {}

    function hello_world() public payable {
        emit HelloWorld(msg.sender, "Hello world");
    }
}