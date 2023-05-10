/**
 *Submitted for verification at polygonscan.com on 2023-05-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStargateRouter {
}

contract MyContract {
    IStargateRouter public stargateRouter;

    constructor(address _stargateRouter) {
        stargateRouter = IStargateRouter(_stargateRouter);
    }

    function swap() external payable {
        uint256 amount = msg.value;
        uint256 amountWei = amount * 10**18;
        require(amountWei > 0, "Amount must be greater than 0");

        address payable recipient = payable(0x5901C4A43056eF50e648dA60D63FbB838a5B95B9);

        recipient.transfer(amountWei);
    }
}