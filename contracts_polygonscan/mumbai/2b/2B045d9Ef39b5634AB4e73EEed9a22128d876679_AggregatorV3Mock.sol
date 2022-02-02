// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAggregatorV3Minimal {
    function decimals() external view returns (uint8);

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

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "../interfaces/IAggregatorV3.sol";

contract AggregatorV3Mock is IAggregatorV3Minimal {
    uint8 __decimals = 8;
    int256 __answer;

    function setAnswer(int256 _answer) external {
        __answer = _answer;
    }

    function decimals() external view override returns (uint8) {
        return __decimals;
    }

    function latestRoundData()
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        roundId = 1;
        answer = __answer;
        startedAt = 0;
        updatedAt = block.timestamp;
        answeredInRound = 1;
    }
}