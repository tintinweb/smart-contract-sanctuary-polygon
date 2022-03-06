// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/ILeverageStrategy.sol";

contract WMaticExposure is ILeverageStrategy {
    event OpenPosition(uint256 amount);

    function openPosition(uint256 amountIn, uint256 borrowAmount) external override {
        emit OpenPosition(amountIn + borrowAmount);
    }

    function closePosition() external override {
        emit OpenPosition(1);
    }

    function calculateSlippage(uint256 amountIn, uint256 borrowAmount) external override {
        // nothing
        emit OpenPosition(amountIn + borrowAmount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILeverageStrategy {
    function openPosition(uint256 amountIn, uint256 borrowAmount) external;

    function closePosition() external;

    function calculateSlippage(uint256 amountIn, uint256 borrowAmount) external;
}