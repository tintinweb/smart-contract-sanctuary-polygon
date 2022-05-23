/**
 *Submitted for verification at polygonscan.com on 2022-05-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract T {

    uint256 a = 55;

    function tst() external {
        a = 61;
        require(false, "does it work?");
    }

    function tst1() external {
        a = 62;
        revert("Something bad happened");
    }
}