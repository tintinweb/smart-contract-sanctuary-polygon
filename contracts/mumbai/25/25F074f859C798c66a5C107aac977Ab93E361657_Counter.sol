//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Counter {
    int public count = 0;

    function increase() public {
        count++;
    }

    function decrease() public {
        count--;
    }

    function reset() public {
        count = 0;
    }
}