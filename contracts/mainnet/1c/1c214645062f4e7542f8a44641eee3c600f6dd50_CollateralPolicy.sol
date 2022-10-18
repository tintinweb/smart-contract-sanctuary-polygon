/**
 * This is a collateral policy controller for the Sugar Dollar an algorithmic stable coin
 * More info on https://cryptocookiesdao.com/
 *
 *
 */

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IOracle} from "./interfaces/IOracle.sol";

/// @title Collateral Policy calculator
contract CollateralPolicy {
    /// @notice The last time the collateral policy was updated
    uint256 public lastUpdate;
    /// @notice The current collateral policy percentage in base 1e8
    uint256 public targetCollateral = 1e8;

    /// @notice After 10 minutes the collateral policy will be updated
    uint256 public constant REFRESH_INTERVAL = 600;

    /// @notice If price is lower than this value, the collateral policy will be increased
    uint256 public constant BAND_BOTTOM = 1e8 - 50_0000;
    /// @notice If price is higher than this value, the collateral policy will be decreased
    uint256 public constant BAND_TOP = 1e8 + 50_0000;

    // @dev MAX_TARGET = 100%
    uint256 public constant MAX_TARGET = 1e8;

    // @dev MIN_TARGET = 75%
    uint256 public constant MIN_TARGET = 75_00_0000;

    /// @notice The step to increase or decrease the collateral policy
    /// @dev 250000 = 0.25%
    uint256 public constant TARGET_STEP = 25_0000;

    /// @notice The oracle price for sUSD to USD
    IOracle public immutable oracle;

    constructor(address _oracle) {
        oracle = IOracle(_oracle);
        lastUpdate = block.timestamp;
    }

    /// @notice Updates the collateral policy and returns the target collateral
    /// @dev Based on the sUSD price and price bands will decide to inc or dec the target collateral
    /// @return Return the current target collatel
    function updateAndGet() external returns (uint256) {
        uint256 _targetCollateral = targetCollateral;

        // If the last update was less than 10 minutes ago, return the current target
        if (block.timestamp - lastUpdate < REFRESH_INTERVAL) {
            return _targetCollateral;
        }
        // Update the last update
        lastUpdate = block.timestamp;

        /// @notice The current sUSD price in USD
        uint256 priceDollar = oracle.susdPrice();

        unchecked {
            if (priceDollar < BAND_BOTTOM && _targetCollateral < MAX_TARGET) {
                // increase TCR only if price is lower than BAND_BOTTOM and havent reach MAX_TARGET
                _targetCollateral += TARGET_STEP;
                _targetCollateral = _targetCollateral > MAX_TARGET ? MAX_TARGET : _targetCollateral;

                // update targetCollateral
                targetCollateral = _targetCollateral;
            } else if (priceDollar > BAND_TOP && MIN_TARGET < _targetCollateral) {
                // decrease TCR only if price is higher than BAND_TOP and havent reach MIN_TARGET
                _targetCollateral -= TARGET_STEP;
                _targetCollateral = _targetCollateral < MIN_TARGET ? MIN_TARGET : _targetCollateral;

                // update targetCollateral
                targetCollateral = _targetCollateral;
            }
        }

        return _targetCollateral;
    }
}

pragma solidity ^0.8.0;

interface IOracle {
    function daiPrice() external returns (uint256);

    /// @notice Returns the price of 1 SUSD based on twap price & chainlink
    /// @return uint256 1 ether SUSD in USD
    function susdPrice() external returns (uint256);

    /// @notice Returns the price of 1 CKIE based on twap price & chainlink
    /// @return uint256 1 ether CKIE in USD
    function cookiePrice() external returns (uint256);
}