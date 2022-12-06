/**
 *Submitted for verification at polygonscan.com on 2022-12-06
*/

pragma solidity 0.8.17;

// SPDX-License-Identifier: UNLICENSED

contract WorldCupOracle {
    uint public latestAnswer = 1e8;
    string public name;
    uint8 public constant decimals = 8;
    address owner;

    constructor(string memory _name) {
        owner = msg.sender;
        name = _name;
    }

    function setName(string memory _name) external {
        require(msg.sender == owner);
        name = _name;
    }

    function setAnswer(uint _latestAnswer) external {
        require(msg.sender == owner);
        require(_latestAnswer >= 1e8 && _latestAnswer <= 8e8);
        latestAnswer = _latestAnswer;
    }
}