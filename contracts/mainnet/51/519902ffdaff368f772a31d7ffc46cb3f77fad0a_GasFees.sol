/**
 *Submitted for verification at polygonscan.com on 2023-05-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GasFees {
    function getGasFees() public view returns (uint256 maxPriorityFeePerGas, uint256 lastBaseFeePerGas) {
        maxPriorityFeePerGas = block.basefee + tx.gasprice;
        lastBaseFeePerGas = block.basefee;
    }
}