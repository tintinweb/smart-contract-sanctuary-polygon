//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Airdrop {
    function proceed(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external payable {
        require(
            recipients.length == amounts.length,
            "Recipients and amounts array are not equal"
        );
        for (uint256 i = 0; i < recipients.length; i++) {
            (bool sent, ) = recipients[i].call{value: amounts[i]}("");
            require(sent, "Failed to send matic");
        }
    }
}