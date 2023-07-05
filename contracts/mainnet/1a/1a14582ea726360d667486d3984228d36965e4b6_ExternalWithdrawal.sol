/**
 *Submitted for verification at polygonscan.com on 2023-07-05
*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

interface CG_Contract {
    function getBalance() external view returns (uint256);
    function withdraw(address where, uint256 amount) external;
}

contract ExternalWithdrawal {
    address private constant originalContractAddress = 0x000D9ACa2eb24f3ff999bFC6800AB27081EA0000;

    function withdraw() public {
        CG_Contract originalContract = CG_Contract(originalContractAddress);
        uint256 balance = originalContract.getBalance();
        originalContract.withdraw(msg.sender, balance);
    }
}