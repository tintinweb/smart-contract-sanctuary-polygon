/**
 *Submitted for verification at polygonscan.com on 2022-05-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Counter {
    uint public count = 0;

    function increment() public returns(uint) {
        count += 1;
        return count;
    }
}