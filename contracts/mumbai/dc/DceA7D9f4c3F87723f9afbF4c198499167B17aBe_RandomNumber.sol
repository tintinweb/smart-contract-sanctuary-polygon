/**
 *Submitted for verification at polygonscan.com on 2022-12-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract RandomNumber{

    uint256 public randomNumber;
    uint256 nonce;

    function requestRandomNumber() external{
        randomNumber = generateRandom();
        nonce++;
    }

    function generateRandom() internal view returns(uint256){
        uint256 r_number = uint256(keccak256(abi.encodePacked(
            nonce,
            block.timestamp,
            block.difficulty,
            msg.sender) 
        ));
        r_number = (r_number % 99) + 1;
        return r_number;
    }
}