/**
 *Submitted for verification at polygonscan.com on 2022-11-07
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

contract Custom {

    bool public a;

    error Sux(string reason);

    function doSomething(string memory reason) external {
        a = true;
        revert Sux(reason);
    }

    function somethingElse(string memory reason) external {
        a = true;
        revert(reason);
    }
}