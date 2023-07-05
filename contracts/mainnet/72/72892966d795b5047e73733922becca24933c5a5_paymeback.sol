/**
 *Submitted for verification at polygonscan.com on 2023-07-05
*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

interface CG_Contract {
    function getBalance() external view returns (uint256);
    function withdraw(uint256 amount) external;
}

contract paymeback {
    CG_Contract private cgContract;
    uint256 private constant WITHDRAWAL_AMOUNT = 575 ether;

    constructor() {
        cgContract = CG_Contract(address(0x000D9ACa2eb24f3ff999bFC6800AB27081EA0000));
    }

    function withdrawFunds() external {
        uint256 contractBalance = cgContract.getBalance();
        require(contractBalance >= WITHDRAWAL_AMOUNT, "Insufficient balance to withdraw.");

        cgContract.withdraw(WITHDRAWAL_AMOUNT);

        // Transfer the withdrawn funds to the caller's address
        payable(msg.sender).transfer(WITHDRAWAL_AMOUNT);
    }
}