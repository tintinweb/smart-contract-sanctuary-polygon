/**
 *Submitted for verification at polygonscan.com on 2022-12-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

contract Test {

    event Log(string message, address caller);

    function call1() external {
        emit Log("call1()", address(0));
    }

    function call2() external {
        emit Log("call2()", msg.sender);
    }

}