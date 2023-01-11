// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract ActchnCounterTest
{
    bool public locked;
    uint256 public counter;

    function enabledLock()
        public
    {
        locked = true;
    }

    function disableLock()
        public
    {
        locked = false;
    }

    function incrementCounter()
        public
    {
        counter++;
    }
}