/**
 *Submitted for verification at polygonscan.com on 2022-10-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract MockTarget {
    
    int private count = 0;
    function incrementCounter() public {
        count += 1;
    }
    function decrementCounter() public {
        count -= 1;
    }

    function getCount() public view returns (int) {
        return count;
    }
}