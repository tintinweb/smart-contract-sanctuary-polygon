/**
 *Submitted for verification at polygonscan.com on 2022-12-16
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

contract Lock {
    string public text = "text";

    error CustomError();

    function functionWhichWillRevert() external {
        revert CustomError();
    }

}