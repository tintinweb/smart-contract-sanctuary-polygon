/**
 *Submitted for verification at polygonscan.com on 2023-07-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract ErrorTest {
    bool public isClicked;
    error Failed(uint256 epoch);

    function clickFailed() external {
        if (!isClicked) {
            revert Failed(block.timestamp);
        }
        isClicked = true;
    }

    function setToFalse() external {
        isClicked = false;
    }
}