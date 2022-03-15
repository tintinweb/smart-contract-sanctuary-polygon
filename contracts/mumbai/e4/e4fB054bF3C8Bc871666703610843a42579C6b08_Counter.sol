/**
 *Submitted for verification at polygonscan.com on 2022-03-14
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Counter {
    uint public counter;

    constructor() {
    }

    function increment() public {
        counter++;
    }

    function getCounter() public view returns (uint) {
        return counter;
    }
}