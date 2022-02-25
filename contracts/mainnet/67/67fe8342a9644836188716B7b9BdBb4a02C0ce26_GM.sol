/**
 *Submitted for verification at polygonscan.com on 2022-02-25
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract GM {
    event GmEvent(address indexed _from, string indexed message);

    constructor() {}

    function gm() public payable {
        emit GmEvent(msg.sender, "gm");
    }
}