// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract AAAT {
    uint256 public total;
    
    function increase(uint256 amount) public {
        total += amount;
    }
}