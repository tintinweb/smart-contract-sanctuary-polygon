// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

contract DemoSwap {
    enum SwapStatus {
        SwapNotInitiated,
        Deposited,
        Finished,
        Refunded
    }

    mapping(bytes => SwapStatus) public swapHashToStatus;

    function deposit(bytes calldata swapHash) external payable {
        require(swapHashToStatus[swapHash] == SwapStatus.SwapNotInitiated, "Swap already initiated");
        swapHashToStatus[swapHash] = SwapStatus.Deposited;
    }

    function isDeposited(bytes calldata swapHash) external view returns (bool result) {
        return swapHashToStatus[swapHash] == SwapStatus.Deposited;
    }

    function redeem(bytes calldata swapHash) external {
        require(swapHashToStatus[swapHash] == SwapStatus.Deposited, "Swap not deposited");
        swapHashToStatus[swapHash] = SwapStatus.Finished;
    }

    function registerSwap() external {}

    function refund(bytes calldata swapHash) external {
        require(swapHashToStatus[swapHash] == SwapStatus.Deposited, "Swap not deposited");
        // Check somewhere time lock
        swapHashToStatus[swapHash] = SwapStatus.Refunded;
    }
}