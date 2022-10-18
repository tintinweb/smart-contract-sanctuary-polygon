/**
 *Submitted for verification at polygonscan.com on 2022-10-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract LoverDisperse {
    address public owner;

    constructor() {
        owner = address(msg.sender);
    }

    function disperseEther(address payable[] memory recipients, uint256 value)
        public
        payable
    {
        for (uint256 i = 0; i < recipients.length; i++)
            recipients[i].transfer(value);
        uint256 balance = address(this).balance;
        if (balance > 0) payable(msg.sender).transfer(balance);
    }
}