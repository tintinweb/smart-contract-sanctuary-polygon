// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

contract DCA {
    /**
    * Public counter variable
    */
    uint public counter;

    event upkeepPerfomed(uint256 timestamp);

    constructor() {
    }

    function performDCA() public {
        counter = counter + 1;
        emit upkeepPerfomed(block.timestamp);
    }
}