/**
 *Submitted for verification at polygonscan.com on 2023-05-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AWorthyProject {
    string public name;
    event ReceivedFunding(address sender, uint amount, string message);

    constructor(string memory _name) {
        name = _name;
    }

    receive() external payable {
        emit ReceivedFunding(msg.sender, msg.value, "we got paid");
    }
}