/**
 *Submitted for verification at polygonscan.com on 2022-02-26
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

    function execute(
        address to,
        bytes memory data,
        uint256 value,
        uint256 chainId,
        uint256 gas,
        uint256 maxGasPrice,
        Assets[] memory assets,
        bytes memory metadata
    ) external {
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
}