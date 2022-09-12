/**
 *Submitted for verification at polygonscan.com on 2022-09-12
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Dummy {

    event Deposit(address recipient, uint256 inputAmount, uint256 outputAmount, uint256 widgetId);

    function depositTest(address recipient, uint256 inputAmount, uint256 outputAmount, uint256 widgetId) public {
        emit Deposit(recipient, inputAmount, outputAmount, widgetId);
    }
}