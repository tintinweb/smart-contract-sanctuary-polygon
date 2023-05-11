// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IPricer {
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 fee
    ) external pure returns (uint);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./interfaces/IPricer.sol";

contract UniswapV2Pricer is IPricer {

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 fee
    ) public pure override returns (uint amountOut) {
        uint256 amountInWithFee = amountIn * (10000 - fee);
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 10000 + amountInWithFee;
        amountOut = numerator / denominator;
    }
}