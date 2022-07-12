// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract keepers {

    uint256 public count;

    function increment() public {
        count = count + 1;
    }
    
}