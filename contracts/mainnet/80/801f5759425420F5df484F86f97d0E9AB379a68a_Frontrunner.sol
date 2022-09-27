/**
 *Submitted for verification at polygonscan.com on 2022-09-26
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.7;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IDODO {
    function flashLoan(
        uint256 baseAmount,
        uint256 quoteAmount,
        address assetTo,
        bytes calldata data
    ) external;

    function _BASE_TOKEN_() external view returns (address);
}

contract Frontrunner {
    address private immutable owner;

    constructor() {
        owner = msg.sender;
    }

    function frontrun(
        address flashLoanPool,
        uint256 loanAmount,
        address loanToken,
        address frontrunTarget,
        bytes calldata frontrunData
    ) external {
        bytes memory data = abi.encode(flashLoanPool, loanToken, loanAmount, frontrunTarget, frontrunData);
        address flashLoanBase = IDODO(flashLoanPool)._BASE_TOKEN_();
        if (flashLoanBase == loanToken) {
            IDODO(flashLoanPool).flashLoan(loanAmount, 0, address(this), data);
        } else {
            IDODO(flashLoanPool).flashLoan(0, loanAmount, address(this), data);
        }
    }

    function DVMFlashLoanCall(
        address sender,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) external {
        _flashLoanCallBack(sender, baseAmount, quoteAmount, data);
    }

    function DPPFlashLoanCall(
        address sender,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) external {
        _flashLoanCallBack(sender, baseAmount, quoteAmount, data);
    }

    function DSPFlashLoanCall(
        address sender,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) external {
        _flashLoanCallBack(sender, baseAmount, quoteAmount, data);
    }

    function _flashLoanCallBack(
        address,
        uint256,
        uint256,
        bytes calldata data
    ) internal {
        (
            address flashLoanPool,
            address loanToken,
            uint256 loanAmount,
            address frontrunTarget,
            bytes memory frontrunData
        ) = abi.decode(data, (address, address, uint256, address, bytes));
        IERC20(loanToken).approve(frontrunTarget, loanAmount);
        (bool success, bytes memory result) = frontrunTarget.call(frontrunData);
        assembly {
            if iszero(success) {
                revert(add(result, 32), mload(result))
            }
        }
        IERC20(loanToken).transfer(flashLoanPool, loanAmount);
        IERC20(loanToken).transfer(owner, IERC20(loanToken).balanceOf(address(this)));
    }
}