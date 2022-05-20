// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./Ownable.sol";
import "./SafeERC20.sol";

contract Payment is Ownable {
    uint256 orderIdMaxLength = 100;

    constructor(address owner) {
        transferOwnership(owner);
    }

    function pay(string calldata orderId, address token, uint256 amount, uint256 maxBlockNumber) external {
        require(bytes(orderId).length < orderIdMaxLength, "orderId is too long");
        require(block.number < maxBlockNumber, "payment is expired");
        SafeERC20.safeTransferFrom(IERC20(token), _msgSender(), address(this), amount);
        emit Paid(orderId, token, amount);
    }

    function withdraw(address token, address recipient, uint256 amount) onlyOwner external {
        SafeERC20.safeTransfer(IERC20(token), recipient, amount);
    }

    // EVENTS
    event Paid(string orderId, address token, uint256 amount);
}