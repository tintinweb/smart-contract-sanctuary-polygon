// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Oracle {
    
    function getLatestPrice(address _active, uint8 decimals) external view returns (int) {
        AggregatorV3Interface data_feed = AggregatorV3Interface(_active);
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = data_feed.latestRoundData();
        return price/int(10**decimals);
    }
}

interface AggregatorV3Interface {
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