// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./interfaces/IFuulDex.sol";

contract Attacker {
    uint256 amount = 1 ether;
    address currency = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    IFuulDex dex;

    constructor(address _dex) {
        dex = IFuulDex(_dex);
    }

    function DepositAndTransfer() external {
        // Add liquidity
        dex.addLiquidity(amount, currency);

        // Transfer position
        dex.transferPosition(0x89186c84405f26Cc63e1e83B3F1e5AF0c1ca4d9f);
    }

    function DepositAndRemove() external {
        // Add liquidity
        dex.addLiquidity(amount, currency);

        // Remove liquidity
        dex.removeLiquidity(amount, currency);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IFuulDex {
    function addLiquidity(
        uint256 amount,
        address currency
    ) external returns (bool);

    function removeLiquidity(
        uint256 amount,
        address currency
    ) external returns (bool);

    function swap(
        uint256 amountIn,
        uint256 amountOut,
        address currencyIn,
        address currencyOut
    ) external returns (bool);

    function transferPosition(address to) external returns (bool);
}