/**
 *Submitted for verification at polygonscan.com on 2022-10-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; //version

contract OwnerContract {
    uint256 public couter;

    function updateCounter(uint256 condtion) public {
        if (condtion == 1) {
            couter = couter + 1;
        } else {
            couter = couter - 1;
        }
    }
}