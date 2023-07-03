/**
 *Submitted for verification at polygonscan.com on 2023-07-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract BatchTransfer {
    address public tokenAddress; // 代币A的合约地址

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
    }

    function batchTransfer(address[] memory recipients, uint256[] memory amounts) external {
        require(recipients.length == amounts.length, "Invalid input");

        IERC20 token = IERC20(tokenAddress);

        for (uint256 i = 0; i < recipients.length; i++) {
            require(token.transfer(recipients[i], amounts[i]), "Token transfer failed");
        }
    }
}