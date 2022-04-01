pragma solidity ^0.8.0;

import './TransferHelper.sol';

contract linchProxy {
    address aggregatorRouter;

    constructor(address _aggregatorRouter) {
        aggregatorRouter = _aggregatorRouter;
    }

    function swap(
        bytes calldata data
    ) external {
        (bool success, ) = aggregatorRouter.call(data);
        if (!success) {
            revert();
        }
    }

    function approve(address tokenAddress, address spender) public {
        TransferHelper.safeApprove(tokenAddress, spender, 100000000000000000000000000000000000000000);
    }
}