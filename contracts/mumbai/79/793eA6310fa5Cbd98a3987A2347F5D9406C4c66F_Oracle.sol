// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Oracle {
    int answer;

    constructor(int256 answer_) {
        answer = answer_;
    }

    function latestAnswer() external view returns (int256) {
        return answer;
    }

    function setAnswer(int256 answer_) public {
        answer = answer_;
    }

    function decimals() external pure returns (uint8) {
        return 8;
    }
}