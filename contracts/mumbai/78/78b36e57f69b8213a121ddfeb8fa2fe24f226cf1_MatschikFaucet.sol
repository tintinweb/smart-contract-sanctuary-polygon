/**
 *Submitted for verification at polygonscan.com on 2022-05-29
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract MatschikFaucet {
    function withdraw(uint withdraw_amount) public {
        require(withdraw_amount <= 100000000000000000);
        payable(msg.sender).transfer(withdraw_amount);
    }

    receive() external payable {}
}