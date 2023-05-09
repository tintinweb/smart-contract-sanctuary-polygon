//SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "./AbstractAveraging.sol";

/// @title ArithmeticAveraging
/// @notice A strategy for calculating weighted averages using the arithmetic mean.
contract ArithmeticAveraging is AbstractAveraging {
    /// @inheritdoc IAveragingStrategy
    function calculateWeightedValue(uint256 value, uint256 weight) external pure override returns (uint256) {
        return value * weight;
    }

    /// @inheritdoc IAveragingStrategy
    function calculateWeightedAverage(
        uint256 totalWeightedValues,
        uint256 totalWeight
    ) external pure override returns (uint256) {
        if (totalWeight == 0) {
            // Ambiguous result, so we revert
            revert TotalWeightCannotBeZero();
        }

        return totalWeightedValues / totalWeight;
    }
}