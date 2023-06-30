/**
 *Submitted for verification at polygonscan.com on 2023-06-29
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

contract TestContract {
    
    uint256 private count = 0;

    function increment() public {
        count += 1;
    }
    
    function getCount() public view returns (uint256) {
        return count;
    }

}