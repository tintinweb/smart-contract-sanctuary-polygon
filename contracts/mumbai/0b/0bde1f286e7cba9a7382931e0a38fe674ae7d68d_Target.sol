// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Target {
    uint256 public count;

    event Changed(uint256 count);

    constructor() {
        count = 0;
    }

    function increment() public {
        count += 1;
        emit Changed(count);
    }
}