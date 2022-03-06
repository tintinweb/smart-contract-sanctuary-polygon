// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/ILeverageStrategy.sol";

contract WMaticExposure is ILeverageStrategy {
    event OpenPosition(uint256 amount, address who);

    function openPosition(uint256 amountIn, uint256 borrowAmount) external override {
        emit OpenPosition(amountIn + borrowAmount, msg.sender);
    }

    function closePosition() external override {
        emit OpenPosition(1, msg.sender);
    }

    function calculateSlippage(uint256 amountIn, uint256 borrowAmount) external override {
        // nothing
        emit OpenPosition(amountIn + borrowAmount, msg.sender);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILeverageStrategy {
    function openPosition(uint256 amountIn, uint256 borrowAmount) external;

    function closePosition() external;

    function calculateSlippage(uint256 amountIn, uint256 borrowAmount) external;
}