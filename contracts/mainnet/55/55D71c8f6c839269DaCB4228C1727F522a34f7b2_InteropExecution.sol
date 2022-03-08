/**
 *Submitted for verification at polygonscan.com on 2022-03-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract InteropExecution {
    struct Assets {
        address token;
        uint256 amount;
    }

    uint256 public vnonce;

    event Execute (
        address from,
        address to,
        bytes data,
        uint256 value,
        uint256 chainId,
        uint256 gas,
        uint256 maxGasPrice,
        Assets[] assets,
        bytes metadata,
        uint256 vnonce
    );

    event ConfirmExecution (
        bytes32 interopTx,
        bytes32 targetTx,
        address miner,
        address user,
        uint256 totalGasPrice,
        uint256 targetGasFee,
        uint256 vnonce
    );

    event FailExecution (
        bytes32 interopTx,
        bytes32 targetTx,
        address miner,
        address user,
        uint256 totalGasPrice,
        uint256 targetGasFee,
        uint256 vnonce
    );

    function execute(
        address to,
        bytes memory data,
        uint256 value,
        uint256 chainId,
        uint256 gas,
        uint256 maxGasPrice,
        Assets[] memory assets,
        bytes memory metadata
    ) external payable {
        emit Execute (
            msg.sender,
            to,
            data,
            value, 
            chainId,
            gas,
            maxGasPrice,
            assets,
            metadata,
            vnonce
        );
        vnonce++;
    }

    function confirmExecution (
        bytes32 interopTx_,
        bytes32 targetTx_,
        address miner_,
        address user_,
        uint256 totalGasPrice_,
        uint256 targetGasFee_,
        uint256 vnonce_
    ) external payable {
        (bool status, ) = miner_.call{value: targetGasFee_}("");
        require(status, "sending-miner-fee-failed");
        (status, ) = user_.call{value: totalGasPrice_ - targetGasFee_}("");
        require(status, "sending-user-refund-failed");

        emit ConfirmExecution(
            interopTx_,
            targetTx_,
            miner_,
            user_,
            totalGasPrice_,
            targetGasFee_,
            vnonce_
        );

    }

    function failExecution (
        bytes32 interopTx_,
        bytes32 targetTx_,
        address miner_,
        address user_,
        uint256 totalGasPrice_,
        uint256 targetGasFee_,
        uint256 vnonce_
    ) external payable {
        (bool status, ) = miner_.call{value: targetGasFee_}("");
        require(status, "sending-miner-fee-failed");
        (status, ) = user_.call{value: totalGasPrice_ - targetGasFee_}("");
        require(status, "sending-user-refund-failed");

        emit FailExecution(
            interopTx_,
            targetTx_,
            miner_,
            user_,
            totalGasPrice_,
            targetGasFee_,
            vnonce_
        );

    }
}