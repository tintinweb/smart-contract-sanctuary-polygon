// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

/// @notice Contract that have necessary for chainlink oracle interface and returning constant price
contract ConstPriceChainlinkOracle {
    /// @notice Constant price to be returned on every call
    int256 public immutable price;

    /// @notice Price's decimals
    uint8 public immutable decimals;

    /// @notice Creates a new contract
    /// @param price_ Constant price
    /// @param decimals_ Price's decimals
    constructor(int256 price_, uint8 decimals_) {
        price = price_;
        decimals = decimals_;
    }

    /// @notice Returns chainlink oracle compatible price data
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (0, price, 0, block.timestamp, 0);
    }
}