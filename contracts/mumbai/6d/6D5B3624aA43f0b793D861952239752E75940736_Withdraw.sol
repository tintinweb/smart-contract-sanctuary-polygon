/**
 *Submitted for verification at polygonscan.com on 2022-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

contract Withdraw {
    event Withdrawn(
        bytes indexed withdrawalId,
        uint256 amount,
        address userAddress
    );

    function triggerWithdraw(
        bytes calldata withdrawId,
        uint256 amount,
        address userAddress
    ) public {
        emit Withdrawn(withdrawId, amount, userAddress);
    }
}