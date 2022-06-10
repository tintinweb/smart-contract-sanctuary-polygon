// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Withdraw {
    event Withdrawn(
        string indexed withdrawalId,
        uint256 amount,
        address userAddress
    );

    function triggerWithdraw(
        string calldata withdrawId,
        uint256 amount,
        address userAddress
    ) public {
        emit Withdrawn(withdrawId, amount, userAddress);
    }
}