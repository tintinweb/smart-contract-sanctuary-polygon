// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface AggregatorInterface {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract MaticPriceOracle {
    AggregatorInterface internal priceFeed;

    error HeartbeatNotFulfilled();

    /**
     * Network: Polygon
     * Data Feed: MATIC/USD
     * Data Feed Proxy Address: 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0
     */
    constructor() {
        priceFeed = AggregatorInterface(
            0xAB594600376Ec9fD91F8e885dADF0CE036862dE0
        );
    }

    /// @notice Returns the underlying price
    function getUnderlyingPrice() public view returns (uint256) {
        (, int256 price, , uint256 updatedAt, ) = priceFeed.latestRoundData();

        if ((block.timestamp - updatedAt) > 25) {
            revert HeartbeatNotFulfilled();
        }

        return uint256(price);
    }
}