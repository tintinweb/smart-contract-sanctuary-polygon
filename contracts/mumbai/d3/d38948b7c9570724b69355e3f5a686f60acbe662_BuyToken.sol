/**
 *Submitted for verification at polygonscan.com on 2022-03-30
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract BuyToken {
    address payable oscowner;

    event Transaction(address user, uint256 tokenId, uint256 value);

    constructor(address payable _oscowner) {
        oscowner = _oscowner;
    }

    function buy_token(uint256 tokenId) public payable {
        require(msg.value > 0, "value error");
        oscowner.transfer(msg.value);

        emit Transaction(msg.sender, tokenId, msg.value);
    }
}