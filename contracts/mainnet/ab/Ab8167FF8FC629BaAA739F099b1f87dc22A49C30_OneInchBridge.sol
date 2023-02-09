pragma solidity ^0.8.6;

import "./interfaces/OneInchInterfaces.sol";
import "../interfaces/IOneInchBridge.sol";

contract OneInchBridge is IOneInchBridge {
    function swap(
        address oneInchAddress,
        uint256 minReturnAmount,
        IAggregationExecutor executor,
        SwapDescription calldata desc,
        bytes calldata permit,
        bytes calldata data
    ) external override {
        uint256 amount = desc.srcToken.balanceOf(address(this));
        desc.srcToken.approve(oneInchAddress, amount);

        SwapDescription memory updatedDescription = SwapDescription({
            srcToken: desc.srcToken,
            dstToken: desc.dstToken,
            srcReceiver: desc.srcReceiver,
            dstReceiver: payable(address(this)),
            amount: amount,
            minReturnAmount: minReturnAmount, // This needs to be improved eventually
            flags: desc.flags
        });

        OneInchInterface oneInch = OneInchInterface(oneInchAddress);

        (uint256 returnAmount, uint256 spentAmount) = oneInch.swap(
            executor,
            updatedDescription,
            permit,
            data
        );

        emit DEFIBASKET_ONEINCH_SWAP(spentAmount, returnAmount);
    }
}

import "@uniswap/v2-periphery/contracts/interfaces/IERC20.sol";

interface IAggregationExecutor {
    /// @notice propagates information about original msg.sender and executes arbitrary data
    function execute(address msgSender) external payable; // 0x4b64e492
}

interface OneInchInterface {
    /// @notice propagates information about original msg.sender and executes arbitrary data
    function swap(
        IAggregationExecutor executor,
        SwapDescription calldata desc,
        bytes calldata permit,
        bytes calldata data
    ) external payable returns (uint256 returnAmount, uint256 spentAmount);
}

struct SwapDescription {
    IERC20 srcToken;
    IERC20 dstToken;
    address payable srcReceiver;
    address payable dstReceiver;
    uint256 amount;
    uint256 minReturnAmount;
    uint256 flags;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "../OneInch/interfaces/OneInchInterfaces.sol";

interface IOneInchBridge {
    event DEFIBASKET_ONEINCH_SWAP(uint256 spentAmount, uint256 returnAmount);

    function swap(
        address oneInchAddress,
        uint256 minReturnAmount,
        IAggregationExecutor executor,
        SwapDescription calldata desc,
        bytes calldata permit,
        bytes calldata data
    ) external;
}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}