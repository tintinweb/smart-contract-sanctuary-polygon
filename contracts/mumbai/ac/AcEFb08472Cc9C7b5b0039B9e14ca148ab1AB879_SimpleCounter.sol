//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleCounter {
    uint256 public counter;

    function incrementCounter() public {
        counter++;
    }
}