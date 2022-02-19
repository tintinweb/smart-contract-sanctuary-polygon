/**
 *Submitted for verification at polygonscan.com on 2022-02-19
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.10;

contract Counter {
    uint public count = 0;
    
    function increment() public returns(uint) {
        count += 1;
        return count;
    }
}