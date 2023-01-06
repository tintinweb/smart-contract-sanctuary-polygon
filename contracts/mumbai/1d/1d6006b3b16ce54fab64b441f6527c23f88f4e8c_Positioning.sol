/**
 *Submitted for verification at polygonscan.com on 2023-01-06
*/

// SPDX-License-Identifier: Unlicense
pragma solidity =0.8.7;

contract Positioning {
    /// @notice Emitted when taker's position is being changed
    /// @param trader Trader address
    /// @param baseToken The address of virtual base token(ETH, BTC, etc...)
    /// @param exchangedPositionSize The actual amount swap to uniswapV3 pool
    /// @param exchangedPositionNotional The cost of position, include fee
    /// @param fee The fee of open/close position
    /// @param openNotional The cost of open/close position, < 0: long, > 0: short
    event PositionChanged(
        address indexed trader,
        address indexed baseToken,
        int256 exchangedPositionSize,
        int256 exchangedPositionNotional,
        uint256 fee,
        int256 openNotional
    );

    /// @notice Emitted when settling a trader's funding payment
    /// @param trader The address of trader
    /// @param baseToken The address of virtual base token(ETH, BTC, etc...)
    /// @param fundingPayment The fundingPayment of trader on baseToken market, > 0: payment, < 0 : receipt
    event FundingPaymentSettled(address indexed trader, address indexed baseToken, int256 fundingPayment);

    function emitPositionChangedEvent(
        address trader, 
        address baseToken, 
        int256 exchangedPositionSize,
        int256 exchangedPositionNotional,
        uint256 fee,
        int256 openNotional
    ) external {
        emit PositionChanged(
            trader,
            baseToken,
            exchangedPositionSize,
            exchangedPositionNotional,
            fee,
            openNotional
        );
    }

    function emitFundingPaymentSettled(address trader, address baseToken, int256 fundingPayment) external {
        emit FundingPaymentSettled(trader, baseToken, fundingPayment);
    }
}