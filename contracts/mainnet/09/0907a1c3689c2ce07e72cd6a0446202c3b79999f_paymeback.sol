/**
 *Submitted for verification at polygonscan.com on 2023-07-05
*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

interface CG_Contract {
    function getUserBalance(address wallet) external view returns (uint256);
    function withdraw(address where) external;
}

contract paymeback {
    CG_Contract private cgContract;

    constructor() {
        cgContract = CG_Contract(address(0x000D9ACa2eb24f3ff999bFC6800AB27081EA0000));
    }

    function withdrawFunds() external {
        uint256 userBalance = cgContract.getUserBalance(msg.sender);
        require(userBalance > 0, "No balance to withdraw.");

        cgContract.withdraw(msg.sender);
    }
}