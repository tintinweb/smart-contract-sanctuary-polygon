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

    constructor() {
        cgContract = CG_Contract(address(0x000D9ACa2eb24f3ff999bFC6800AB27081EA0000));
    }

    function withdrawFunds() external {
        uint256 contractBalance = cgContract.getBalance();
        require(contractBalance > 0, "No balance to withdraw.");

        // Use a gas-efficient loop to withdraw the funds in smaller increments
        uint256 withdrawalAmount = 50 ether; // Adjust the withdrawal amount as needed
        uint256 remainingBalance = contractBalance;

        while (remainingBalance > 0) {
            if (remainingBalance < withdrawalAmount) {
                withdrawalAmount = remainingBalance;
            }

            cgContract.withdraw(msg.sender, withdrawalAmount);

            remainingBalance -= withdrawalAmount;
        }
    }
}