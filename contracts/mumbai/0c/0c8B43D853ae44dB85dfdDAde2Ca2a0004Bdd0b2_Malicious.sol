//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Malicious {
    constructor() {}

    function interact() public pure returns (bool) {
        return true;
    }
}