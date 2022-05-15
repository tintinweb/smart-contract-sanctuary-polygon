/**
 *Submitted for verification at polygonscan.com on 2022-05-14
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract aaa {

    event BetBegin(uint256[] results); //游戏开始通知
    event BetBegin1(string name, uint256 results); //游戏开始通知

    function test() public{
       uint256[] memory results = new uint256[](3);
        for (uint i = 0; i < 3; i++) {
            results[i] = i;
        }
        emit BetBegin(results);
    }

        function test1(uint n) public{
        emit BetBegin1("aimili", n);
    }
}