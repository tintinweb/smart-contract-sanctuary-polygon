/**
 *Submitted for verification at polygonscan.com on 2022-06-26
*/

pragma solidity ^0.4.21;

contract ScoreInterface {
    function hit() public;
    function score() public view returns (uint);
}

contract ScoreV1 is ScoreInterface {
    mapping (address => uint) scoreMap;

    function hit() public {
        scoreMap[msg.sender] = scoreMap[msg.sender] + 10;
    }

    function score() public view returns (uint) {
        return scoreMap[msg.sender];
    }
}