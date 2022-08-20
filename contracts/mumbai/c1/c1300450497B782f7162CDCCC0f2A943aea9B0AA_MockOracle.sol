// Based on AAVE protocol
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/// @title IPriceOracleGetter interface
interface IPriceOracleGetter {
    /// @dev returns the asset price in ETH
    function getAssetPrice(address _asset) external view returns (uint256);

    /// @dev returns the reciprocal of asset price
    function getAssetPriceReciprocal(address _asset)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {IPriceOracleGetter} from "../interfaces/IPriceOracleGetter.sol";

contract MockOracle is IPriceOracleGetter {
    mapping(address => uint256) currentPrices;

    constructor(address _asset, uint256 price) {
        currentPrices[_asset] = price;
    }

    function updateCurrentPrices(address _asset, uint256 price)
        external
        returns (uint256)
    {
        return currentPrices[_asset] = price;
    }

    /// @dev returns the asset price in ETH
    function getAssetPrice(address _asset) external view returns (uint256) {
        return currentPrices[_asset];
    }

    /// @dev returns the reciprocal of asset price
    function getAssetPriceReciprocal(address _asset)
        external
        view
        returns (uint256)
    {
        return currentPrices[_asset];
    }
}