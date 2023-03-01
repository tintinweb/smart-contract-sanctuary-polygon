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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "../Paraswap/interfaces/ParaswapIntefaces.sol";

interface IParaswapBridge{
    event DEFIBASKET_PARASWAP_SWAP(uint256 receivedAmount);

    function swap(
        address paraswapAddress,
        SimpleData calldata paraswapParams,
        uint256 amountInPercentage
    ) external;
}

pragma solidity ^0.8.6;

import "@uniswap/v2-periphery/contracts/interfaces/IERC20.sol";

interface ParaswapInterface{
    function simpleSwap(
        SimpleData calldata data
    ) external returns (uint256 receivedAmount);
}

struct SimpleData {
    address fromToken;
    address toToken;
    uint256 fromAmount;
    uint256 toAmount;
    uint256 expectedAmount;
    address[] callees;
    bytes exchangeData;
    uint256[] startIndexes;
    uint256[] values;
    address payable beneficiary;
    address payable partner;
    uint256 feePercent;
    bytes permit;
    uint256 deadline;
    bytes16 uuid;
}

pragma solidity ^0.8.6;

import "./interfaces/ParaswapIntefaces.sol";
import "../interfaces/IParaswapBridge.sol";

contract ParaswapBridge is IParaswapBridge {
    function swap(
        address paraswapAddress,
        SimpleData calldata paraswapParams,
        uint256 amountInPercentage
    ) external override {
        uint256 amount = IERC20(paraswapParams.fromToken).balanceOf(address(this))*amountInPercentage/100000;
        IERC20(paraswapParams.fromToken).approve(paraswapAddress, amount);

        SimpleData memory updatedDescription = SimpleData({
            fromToken: paraswapParams.fromToken,
            toToken: paraswapParams.toToken,
            fromAmount: amount,
            toAmount: paraswapParams.toAmount,
            expectedAmount: paraswapParams.expectedAmount,
            callees: paraswapParams.callees,
            exchangeData: paraswapParams.exchangeData,
            startIndexes: paraswapParams.startIndexes,
            values: paraswapParams.values,
            beneficiary: payable(address(this)),
            partner: paraswapParams.partner,
            feePercent: paraswapParams.feePercent,
            permit: paraswapParams.permit,
            deadline: paraswapParams.deadline,
            uuid: paraswapParams.uuid
        });

        ParaswapInterface paraswap = ParaswapInterface(paraswapAddress);

        uint256 receivedAmount = paraswap.simpleSwap(
            updatedDescription
        );

        emit DEFIBASKET_PARASWAP_SWAP(receivedAmount);
    }
}