/**
 *Submitted for verification at polygonscan.com on 2023-06-25
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

contract Counter {
    uint public count = 0;

    function increment() public returns (uint){
        count+=1;
        return count;
    }
}