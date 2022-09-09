// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

contract Oracle {
    uint80 public counter;

    constructor() {
        counter = 1;
    }

    function decimals() external view returns (uint8) {
        return (uint8(5));
    }

    function description() external view returns (string memory) {
        return (string("TestOracles"));
    }

    function version() external view returns (uint256) {
        return (uint256(500));
    }

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
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
        return (
            counter,
            1*10**8,
            100,
            101,
            counter - 1
        );
    }

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
        return (
            counter,
            1*10**8,
            100,
            101,
            counter - 1
        );
    }
}