/**
 *Submitted for verification at polygonscan.com on 2022-03-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITokenInferface {
    function burn(address to, uint256 amount) external;
}

contract InteropExecution {
    struct Assets {
        address token;
        uint256 amount;
    }

    struct TxData {
        Assets[] assets;
        uint256 totalGasFee;
        uint256 status;
    }

    uint256 public vnonce;
    mapping(uint256 => TxData) public transactions;

    event Execute(
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

    event ConfirmExecution(
        bytes32 interopTx,
        bytes32 targetTx,
        address miner,
        address user,
        uint256 totalGasFee,
        uint256 targetGasFee,
        uint256 vnonce
    );

    event FailExecution(
        bytes32 interopTx,
        bytes32 targetTx,
        address miner,
        address user,
        uint256 totalGasFee,
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
        require(
            msg.value == gas * maxGasPrice,
            "msg.value != gas * maxGasPrice"
        );
        for (uint256 i = 0; i < assets.length; i++) {
            transactions[vnonce].assets.push(assets[i]);
        }
        transactions[vnonce].totalGasFee = gas * maxGasPrice;
        transactions[vnonce].status = 1;
        emit Execute(
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

    function confirmExecution(
        bytes32 interopTx_,
        bytes32 targetTx_,
        address miner_,
        address user_,
        uint256 totalGasFee_,
        uint256 targetGasFee_,
        uint256 vnonce_
    ) external payable {
        (bool status, ) = miner_.call{value: targetGasFee_}("");
        require(status, "sending-miner-fee-failed");
        require(transactions[vnonce_].status == 1, "status-should-be-1");
        (status, ) = user_.call{value: totalGasFee_ - targetGasFee_}("");
        require(status, "sending-user-refund-failed");

        transactions[vnonce_].status = 2;

        Assets[] memory assets = transactions[vnonce_].assets;

        for (uint256 i = 0; i < assets.length; i++) {
            ITokenInferface(assets[i].token).burn(user_, assets[i].amount);
        }

        emit ConfirmExecution(
            interopTx_,
            targetTx_,
            miner_,
            user_,
            totalGasFee_,
            targetGasFee_,
            vnonce_
        );
    }

    function failExecution(
        bytes32 interopTx_,
        bytes32 targetTx_,
        address miner_,
        address user_,
        uint256 totalGasFee_,
        uint256 targetGasFee_,
        uint256 vnonce_
    ) external payable {
        (bool status, ) = miner_.call{value: targetGasFee_}("");
        require(status, "sending-miner-fee-failed");
        (status, ) = user_.call{value: totalGasFee_ - targetGasFee_}("");
        require(status, "sending-user-refund-failed");

        emit FailExecution(
            interopTx_,
            targetTx_,
            miner_,
            user_,
            totalGasFee_,
            targetGasFee_,
            vnonce_
        );
    }
}