/**
 *Submitted for verification at polygonscan.com on 2022-06-24
*/

// SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.8.4;


contract Receive {
    receive() external payable {}

    function claim() external {
        (bool success, ) = msg.sender.call{value: (address(this).balance)}("");
        require(success, "Transfer failed.");
    }
}