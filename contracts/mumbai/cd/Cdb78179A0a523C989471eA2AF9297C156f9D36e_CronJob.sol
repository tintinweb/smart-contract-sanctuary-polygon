// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CronJob {
    uint public counter;

    function increaseCounter() public {
        counter++;
    }
}