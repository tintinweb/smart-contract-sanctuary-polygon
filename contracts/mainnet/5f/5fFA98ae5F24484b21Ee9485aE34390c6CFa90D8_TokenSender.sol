/**
 *Submitted for verification at polygonscan.com on 2023-01-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TokenSender {
    mapping(address => uint) public balances;

    function sendTokens(address[] memory recipients, uint[] memory amounts) public {
        require(recipients.length == amounts.length, "Length of recipients and amounts must match.");

        for (uint i = 0; i < recipients.length; i++) {
            require(amounts[i] > 0, "Amounts must be greater than 0.");
            require(balances[msg.sender] >= amounts[i], "Sender does not have enough tokens.");

            balances[recipients[i]] += amounts[i];
            balances[msg.sender] -= amounts[i];
        }
    }
}