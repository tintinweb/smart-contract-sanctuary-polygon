/**
 *Submitted for verification at polygonscan.com on 2022-04-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract BlokEvents {

event BetTaken(
        uint256 indexed betId,
        address indexed player,
        uint256 indexed betType,
        uint256 amount,
        uint256 blokFee,
        address maker,
        uint256 makerCommitted
    );

    function raiseEvent(uint256  betId,
        address  player,
        uint256  betType,
        uint256 amount,
        uint256 blokFee,
        address maker,
        uint256 makerCommitted ) external {

        emit BetTaken(betId,
        player,
        betType,
        amount,
        blokFee,
        maker,
        makerCommitted);  
    }

}