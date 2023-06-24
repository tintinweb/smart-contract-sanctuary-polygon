/**
 *Submitted for verification at polygonscan.com on 2023-06-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract testContract {
    string private haha;
    uint[] private balls;
    mapping(address => uint[]) private addresses_with_sequence;

    constructor(string memory text, uint[] memory _sequence) {
        haha = text;
        balls = _sequence;
    }
}