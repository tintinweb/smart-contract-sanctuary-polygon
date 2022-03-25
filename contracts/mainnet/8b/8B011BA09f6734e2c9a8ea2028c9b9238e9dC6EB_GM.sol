/**
 *Submitted for verification at polygonscan.com on 2022-03-24
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract GM {
    event GmEvent(address indexed _from, string message);

    constructor() {}

    function gm() public {
        emit GmEvent(msg.sender, "gm");
    }
}