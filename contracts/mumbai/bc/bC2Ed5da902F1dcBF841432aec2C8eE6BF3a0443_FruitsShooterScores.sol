// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Dumb contract for demo
contract FruitsShooterScores {

    mapping(address => uint) bestScore;

    function gameEnded(uint _score, address _player) public {
        if(bestScore[_player] < _score) {
            bestScore[_player] = _score;
        }
    }

    function getBestScore(address _user) public view returns(uint){
        return bestScore[_user];
    }
}