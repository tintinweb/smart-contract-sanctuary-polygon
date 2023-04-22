// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract HillClimbGame {
    uint256 public highScore;
    address public highScoreHolder;
    IERC20 public token;

    constructor(address _token) {
    token = IERC20(_token);
}

    function playGame(uint256 _score) public {
        require(token.balanceOf(msg.sender) >= 100, "Not enough tokens to play the game");
        require(token.allowance(msg.sender, address(this)) >= 100, "Game contract not authorized to spend tokens");
        if (_score > highScore) {
            highScore = _score;
            highScoreHolder = msg.sender;
        }
        token.transferFrom(msg.sender, address(this), 100);
    }
}