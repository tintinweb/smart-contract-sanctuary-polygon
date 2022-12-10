/**
 *Submitted for verification at polygonscan.com on 2022-12-09
*/

pragma solidity ^0.8.7;


contract Test {
    function test() public view returns (uint256) {
        return block.difficulty;
    }
}