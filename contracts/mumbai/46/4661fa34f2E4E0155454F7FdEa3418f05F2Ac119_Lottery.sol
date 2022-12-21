/**
 *Submitted for verification at polygonscan.com on 2022-12-21
*/

/**
 *Submitted for verification at polygonscan.com on 2022-07-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


contract Lottery {

    // Event definations
    event LotteryWinner(address[] participants, address winner, string geohash, uint256 nftId);

    function randomNum(
        uint256 _mod,
        uint256 _seed,
        uint256 _salt
    ) internal view returns (uint256) {
        uint256 num = uint256(
            keccak256(
                abi.encodePacked(block.timestamp, msg.sender, _seed, _salt)
            )
        ) % _mod;
        return num;
    }
    // External functions
    function lottery(address[] memory participantList, uint256 salt, string calldata geohash, uint256 nftId)
        external
        returns (address)
    {
        uint256 number = randomNum(
            participantList.length,
            block.timestamp,
            participantList.length + salt + 1
        );
        emit LotteryWinner(participantList, participantList[number], geohash, nftId);
        return participantList[number];
    }
}