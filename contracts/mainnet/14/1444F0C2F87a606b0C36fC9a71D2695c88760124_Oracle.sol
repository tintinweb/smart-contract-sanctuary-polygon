/**
 *Submitted for verification at polygonscan.com on 2023-04-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface AggregatorV3Interface {
    function description() external view returns (string memory);

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

contract Oracle {
    struct Round {
        string description;
        int256 answer;
        uint256 time;
        uint256 health;
    }

    constructor() payable {}

    function getOraclesData(
        AggregatorV3Interface[] calldata o
    ) external view returns (Round[] memory d) {
        d = new Round[](o.length);
        for (uint32 i; i < o.length; i++) {
            (, int256 answer, , uint256 updatedAt, ) = o[i].latestRoundData();
            d[i] = Round(
                o[i].description(),
                answer,
                updatedAt,
                block.timestamp - updatedAt
            );
        }
    }
}