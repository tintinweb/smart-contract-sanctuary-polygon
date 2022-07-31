/**
 *Submitted for verification at polygonscan.com on 2022-07-30
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

contract Disperse {
    function disperseEther(
        address payable[] memory recipients,
        uint256 value
    ) external payable {
        uint256 i = 0;
        for (; i < recipients.length; ) {
            recipients[i].transfer(value);
            unchecked {
                i += 1;
            }
        }
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(msg.sender).transfer(balance);
        }
    }
}