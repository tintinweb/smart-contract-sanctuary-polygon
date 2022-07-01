/**
 *Submitted for verification at polygonscan.com on 2022-07-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Test {

    uint public num;

    function getNum() external view returns (uint) {
        return num;
    }

    function inc() external {
        num++;
    }

    function dec() external {
        num--;
    }

}