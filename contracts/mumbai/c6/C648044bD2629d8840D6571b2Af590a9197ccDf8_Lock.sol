// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Lock {
    uint256 public counter;

    event Debug(uint256 counter);

    function increase() external {
        counter++;

        emit Debug(counter);
    }
}