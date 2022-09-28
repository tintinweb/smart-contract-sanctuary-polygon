/**
 *Submitted for verification at polygonscan.com on 2022-09-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract Counter {
    uint public count;

    //Function to get the Current Value
    function get() public view returns (uint) {
        return count;
    }

    //Function to increment by 1
    function inc() public {
        count += 1;
    }

    // Function to decrement count by 1
    function dec() public {
        // Function will fail if count = 0

        count -= 1;
    }
}