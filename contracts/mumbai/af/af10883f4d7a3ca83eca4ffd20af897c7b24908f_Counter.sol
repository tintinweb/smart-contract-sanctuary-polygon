/**
 *Submitted for verification at polygonscan.com on 2023-04-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ICounter {
    function performUpkeep() external;
}
contract Counter is ICounter {
    /**
     * Public counter variable
     */
    uint public counter;
    event Perform(uint counter);
    /**
     * Use an interval in seconds and a timestamp to slow execution of Upkeep
     */
    uint public immutable interval;
    uint public lastTimeStamp;

    constructor(uint updateInterval) {
        interval = updateInterval;
        lastTimeStamp = block.timestamp;

        counter = 60;
    }

    function checkUpkeep()
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        canExec = (block.timestamp - lastTimeStamp) > interval;
        if (canExec) {
            execPayload = abi.encodeWithSelector(ICounter.performUpkeep.selector);
        }
    }

    function performUpkeep() external override {
        if ((block.timestamp - lastTimeStamp) > interval) {
            lastTimeStamp = block.timestamp;
            counter = counter + 1;

            emit Perform(counter);
        }
    }
}