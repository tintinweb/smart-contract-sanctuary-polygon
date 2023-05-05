// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract FuulDex {
    event LiquidityAdded(uint256 amount, address currency);
    event LiquidityRemoved(uint256 amount, address currency);

    event LPTokenTransferred(address from, address to);

    event Swap(
        uint256 amountIn,
        uint256 amountOut,
        address currencyIn,
        address currencyOut
    );

    function addLiquidity(
        uint256 amount,
        address currency
    ) external returns (bool) {
        emit LiquidityAdded(amount, currency);
        emit LPTokenTransferred(address(0), msg.sender);

        return true;
    }

    function removeLiquidity(
        uint256 amount,
        address currency
    ) external returns (bool) {
        emit LiquidityRemoved(amount, currency);

        return true;
    }

    function swap(
        uint256 amountIn,
        uint256 amountOut,
        address currencyIn,
        address currencyOut
    ) external returns (bool) {
        emit Swap(amountIn, amountOut, currencyIn, currencyOut);

        return true;
    }

    function transfer(address to) external returns (bool) {
        emit LPTokenTransferred(msg.sender, to);

        return true;
    }
}