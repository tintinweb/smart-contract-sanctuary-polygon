// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "./IERC20.sol";

contract FlashLoanContract {
    event FlashLoan(address indexed tokenBorrow, address indexed tokenPay, uint256 amount);

    function flashLoan(address tokenBorrow, address tokenPay, uint256 amount) external {
        // Perform the flash loan logic here
        // - Get the tokenBorrow from the contract
        IERC20 borrowToken = IERC20(tokenBorrow);
        borrowToken.transfer(msg.sender, amount);

        // - Perform desired operations with the borrowed tokens
        //   Example: Transfer the borrowed tokens to another address
        //   Perform additional operations as per your requirements

        // - Repay the flash loan by transferring tokenPay back to the contract
        IERC20 payToken = IERC20(tokenPay);
        payToken.transferFrom(msg.sender, address(this), amount);

        // Emit an event to indicate the flash loan completion
        emit FlashLoan(tokenBorrow, tokenPay, amount);
    }
}