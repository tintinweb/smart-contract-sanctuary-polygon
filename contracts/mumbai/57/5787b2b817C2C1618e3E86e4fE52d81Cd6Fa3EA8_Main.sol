/**
 *Submitted for verification at polygonscan.com on 2022-03-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Main {
    Good good;

    constructor(address _good) {
        good = Good(_good);
    }

    function callGood() public {
        good.log();
    }

    function bargoodAddress() public {
        return good.getAddress();
    }
}

contract Good {
    event Log(string message);
    event Address(address add);

    function log() public {
        emit Log("Bar was called");
    }

    function getAddress() public {
        emit Address(address(this));
    }
}