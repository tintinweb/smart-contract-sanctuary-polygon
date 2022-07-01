/**
 *Submitted for verification at polygonscan.com on 2022-07-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ExampleSmartContract {
    uint public num = 0;

    constructor () {
        num = 1;
    }

    function _update (uint newValue) private {
        require (newValue > 10, "Value too low");
        num = newValue;
    }

    function update (uint newValue) public {
        _update(newValue);
    }
}