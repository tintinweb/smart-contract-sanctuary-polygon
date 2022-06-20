// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

interface IUniswapV3TickSpacing {
    function tickSpacing() external view returns (int24);
}

contract L2_PolygonMessengerProxy {
    function testTickSpacing(address pool) public returns (int24) {
        return IUniswapV3TickSpacing(pool).tickSpacing();
    }
}