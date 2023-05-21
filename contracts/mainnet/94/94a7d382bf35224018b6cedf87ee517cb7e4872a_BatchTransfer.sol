/**
 *Submitted for verification at polygonscan.com on 2023-05-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract BatchTransfer {
    function transfer(address[] memory recipients, uint256 amount) public payable {
        require(msg.value >= recipients.length * amount, "Insufficient funds");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            payable(recipients[i]).transfer(amount);
        }
    }
}