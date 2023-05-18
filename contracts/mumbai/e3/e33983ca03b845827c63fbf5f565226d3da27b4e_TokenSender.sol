/**
 *Submitted for verification at polygonscan.com on 2023-05-17
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
}

contract TokenSender {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function sendTokens(address tokenAddress, address[] memory recipients, uint256[] memory amounts) external onlyOwner {
        require(recipients.length == amounts.length, "Invalid input lengths");

        IERC20 token = IERC20(tokenAddress);

        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient address");

            require(token.transfer(recipients[i], amounts[i]), "Token transfer failed");
        }
    }
}