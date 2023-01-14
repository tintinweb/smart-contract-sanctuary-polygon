// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract ActchnTest
{
    bool public locked;
    uint256 public counter;
    mapping (address => uint256) addressCounter;

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

    function incrementForAddress(address _address)
        public
    {
        addressCounter[_address]++;
    }
}