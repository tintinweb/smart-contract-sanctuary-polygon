// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

contract OneInchTarget {
    function approveAndSwap(
        address _fromTokenAddress,
        address _router,
        bytes memory _approveData,
        bytes memory _swapData
    ) external {
        _approve(_fromTokenAddress, _approveData);
        _swap(_router, _swapData);
    }

    function _swap(address _router, bytes memory _swapData) private {
        (bool success, ) = _router.call(_swapData);
        require(success, "swap failed");
    }

    function _approve(address _fromTokenAddress, bytes memory _approveData)
        private
    {
        (bool success, ) = _fromTokenAddress.call(_approveData);
        require(success, "approve failed");
    }
}