// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./Context.sol";

contract Mood is Context {

    string private mood;

    event SetMood (address indexed setter, string mood);

    function setMood (string memory _mood) external {
        mood = _mood;
        emit SetMood(_msgSender(), _mood);
    }

    function getMood () external view returns (string memory) {
        return mood;
    }
}