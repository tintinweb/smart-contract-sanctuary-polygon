/**
 *Submitted for verification at polygonscan.com on 2022-12-28
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract Randnum
{
    function rand() external view returns (uint)
    {
        return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) %99 + 1;
    }
}