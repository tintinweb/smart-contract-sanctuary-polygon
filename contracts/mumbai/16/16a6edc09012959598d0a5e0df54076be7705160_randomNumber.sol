/**
 *Submitted for verification at polygonscan.com on 2022-12-23
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract randomNumber{
    function createRandomNumber(uint256 max) external view returns (uint256){
        return uint256(
                keccak256(abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        msg.sender
                    )
                )
            ) % max;
    }
}