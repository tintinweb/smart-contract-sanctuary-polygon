/**
 *Submitted for verification at polygonscan.com on 2022-05-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Counter {
    uint public count;
     
    function increment() public returns(uint) {
        count += 1;
        return count;
    }
}