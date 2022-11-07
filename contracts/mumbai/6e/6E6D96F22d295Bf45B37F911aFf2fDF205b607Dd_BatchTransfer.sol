/**
 *Submitted for verification at polygonscan.com on 2022-11-07
*/

// Sources flattened with hardhat v2.11.2 https://hardhat.org

// File contracts/BatchTransfer.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract BatchTransfer {
    function sendInBatch(address payable[] memory receipts, uint256 amount) external payable {
        uint256 receiptsLength = receipts.length;
        require(msg.value == amount * receiptsLength, "Invalid payable value");
        
        for (uint256 i = 0; i < receipts.length; i++) {
            receipts[i].transfer(amount);
        }
    }
}