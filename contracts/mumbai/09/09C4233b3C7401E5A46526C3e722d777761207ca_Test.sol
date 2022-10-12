/**
 *Submitted for verification at polygonscan.com on 2022-10-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17.0;

contract Test {

    address payable owner;

    constructor() payable {
        owner = payable(msg.sender);
    }

    function test() external {

    }

    function destroy() external {
        selfdestruct(owner);
    }
}