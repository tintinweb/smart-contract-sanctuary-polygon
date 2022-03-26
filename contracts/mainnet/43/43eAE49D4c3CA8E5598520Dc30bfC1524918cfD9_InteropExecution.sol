// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../common/structs.sol";

interface ITokenInferface {
     function burn(address to, uint256 amount) external;
}

interface INSTInferface {
     function burn(address to, uint256 amount) external payable;
}


contract InteropExecution is Structs {
    address public constant INST = 0x0000000000000000000000000000000000069420;
    uint256 public vnonce;
    mapping (uint256 => TxData) public transactions;

    event Execute (
        address from,
        Execution[] executions,
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
        uint256 totalGasFee,
        uint256 targetGasFee,
        uint256 vnonce
    );

    event FailExecution (
        bytes32 interopTx,
        bytes32 targetTx,
        address miner,
        address user,
        uint256 totalGasFee,
        uint256 targetGasFee,
        uint256 vnonce
    );

    function cast (
        InteropExecutionParams memory interopExecutionParams
    ) external payable {
        uint256 totalValue = interopExecutionParams.gas * interopExecutionParams.maxGasPrice;
        for (uint256 i = 0; i < interopExecutionParams.assets.length; i++) {
            transactions[vnonce].assets.push(interopExecutionParams.assets[i]);
            if (
                interopExecutionParams.assets[i].token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE || 
                interopExecutionParams.assets[i].token == INST
            ) {
                totalValue += interopExecutionParams.assets[i].amount;
            }
            // TODO beta: lock
        }
        require(msg.value >= totalValue, "msg.value != totalValue");

        transactions[vnonce].totalGasFee = interopExecutionParams.gas * interopExecutionParams.maxGasPrice;
        transactions[vnonce].status = 1;

        emit Execute (
            msg.sender,
            interopExecutionParams.executions, 
            interopExecutionParams.chainId,
            interopExecutionParams.gas,
            interopExecutionParams.maxGasPrice,
            interopExecutionParams.assets,
            interopExecutionParams.metadata,
            vnonce
        );
        vnonce++;
    }

    function confirmExecution (
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
            if (assets[i].token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE || assets[i].token == INST) {
                INSTInferface(INST).burn{value: assets[i].amount}(user_, assets[i].amount);
            } else {
                ITokenInferface(assets[i].token).burn(user_, assets[i].amount);
            }
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

    function failExecution (
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

contract Structs {
    struct InteropTxData {
        uint256 nonce;
        bytes data;
    }

    struct Execution {
        address to;
        bytes callData;
        uint256 value;
        uint8 operation;
    }

    struct Assets {
        address token;
        uint256 amount;
    }

    struct InteropExecutionParams {
        Execution[] executions;
        uint256 chainId;
        uint256 gas;
        uint256 maxGasPrice;
        Assets[] assets;
        bytes metadata;
    }

    struct TxData {
        Assets[] assets;
        uint256 totalGasFee;
        uint256 status;
    }
}