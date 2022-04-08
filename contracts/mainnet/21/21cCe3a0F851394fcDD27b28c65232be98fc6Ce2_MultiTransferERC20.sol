/**
 *Submitted for verification at polygonscan.com on 2022-04-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/*
This contract is part of GLM payment system. 
Visit https://golem.network for details.
*/

// Only transferFrom is used from IERC20. Note that you need to call approve on GLM 
interface ITransferFrom {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract MultiTransferERC20 {
    ITransferFrom public GLM;

    constructor(ITransferFrom _GLM) {
        GLM = _GLM;
    }

    function batchTransfer(address[] calldata recipients, uint256[] calldata amounts) external {
        require(recipients.length == amounts.length, "recipients.length == amounts.length");
        require(recipients.length > 0, "recipients.length > 0");

        for (uint i = 0; i < recipients.length; ++i) {
            require(GLM.transferFrom(msg.sender, recipients[i], amounts[i]), "transferFrom failed");
        }
    }
}