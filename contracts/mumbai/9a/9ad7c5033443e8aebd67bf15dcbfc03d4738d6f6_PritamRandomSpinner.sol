// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IRandomizer {
    function requestRandomWords() external;

    function s_randomWords(uint256) external view returns (uint256);
}

contract PritamRandomSpinner {
    IRandomizer random;
    mapping(address => uint256) public playerBalance;

    uint256 public one;
    uint256 public two;
    uint256 public three;

    constructor(address _randomizerAddress) {
        random = IRandomizer(_randomizerAddress);
    }

    function spin() public {
        random.requestRandomWords();
        uint256 firstNum = (random.s_randomWords(0) % 6) + 1;
        uint256 secondNum = (random.s_randomWords(1) % 6) + 1;
        uint256 thirdNum = (random.s_randomWords(2) % 6) + 1;

        one = firstNum;
        two = secondNum;
        three = thirdNum;
    }

    receive() external payable {}
}